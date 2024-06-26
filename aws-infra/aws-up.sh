#!/bin/bash

set -e

# Get Platform
PLATFORM="$(uname -s)"
case "${PLATFORM}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    *)          machine="UNKNOWN:${PLATFORM}"
esac

# Grab AWS env variables
if [[  ! -z "${IS_GITHUB_ACTIONS}" ]]; then
  echo "Using Actions ENVs"
else
  source .env
fi

# Build Infra
echo "Running Terraform..."
terraform init
terraform apply -parallelism=1 -auto-approve

# Update .kube/config context
echo "Fetching AKS creds for kubectl"
aws eks update-kubeconfig --region $TF_VAR_region --name $TF_VAR_name-eks

# Grab AWS env variables
if [[  -z "${IS_GITHUB_ACTIONS}" ]]; then
  # Rename contexts
  kubectl config delete-context $TF_VAR_name
  kubectl config rename-context arn:aws:eks:${TF_VAR_region}:${TF_VAR_aws_acccount}:cluster/${TF_VAR_name}-eks $TF_VAR_name
fi


# Install ArgoCD
echo "Installing ArgoCD"
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for argocd to install..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server --namespace argocd --timeout=240s

# Patch insecure flag to argocd server
kubectl patch deploy argocd-server --namespace argocd --type='json' \
  -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/args", "value": [
  "/usr/local/bin/argocd-server",
  "--insecure"
]}]'
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server --namespace argocd --timeout=240s

# Install Argo Applications
echo "Installing nginx-ingress, cert-manager, and Prometheus ArgoCD Applications, Keda"
kubectl apply -f ../argocd/argocd/nginx-ingress.yml --namespace argocd
# Add CERTBOT_EMAIL to cluster-issuer
if [[ "$machine" == "Linux" ]]; then
  sed -i "s/CERTBOT_EMAIL/$CERTBOT_EMAIL/" ../argocd/cert-manager/cluster-issuer.yml
else #MacOS
  sed -i '' "s/CERTBOT_EMAIL/$CERTBOT_EMAIL/" ../argocd/cert-manager/cluster-issuer.yml
fi
kubectl create namespace cert-manager 
kubectl apply -f ../argocd/cert-manager/cert-manager.yml
sleep 30
kubectl apply -f ../argocd/argocd/prom.yml --namespace argocd
kubectl apply -f ../argocd/argocd/keda.yml --namespace argocd

#AWS Only - enable metric server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
sleep 30 #wait for ArgoCD to create namespace

echo "Waiting for Nginx Controller to install..."
for i in {1..10}; do kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=controller --namespace ingress --timeout=240s && break || echo "Waiting for ingress controller..."; sleep 30; done

echo "Waiting for Cert Manager install..."
for i in {1..10}; do kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=cert-manager --namespace cert-manager --timeout=240s && break || echo "Waiting for cert-manager..."; sleep 30; done

echo "Waiting for Prometheus"
for i in {1..10}; do kubectl wait --for=condition=ready pod -l app=kube-prometheus-stack-operator --namespace monitoring --timeout=240s && break || echo "Waiting for prometheus..."; sleep 30; done

echo "Waiting for Keda"
for i in {1..10}; do kubectl wait --for=condition=ready pod -l app=keda-operator --namespace keda --timeout=240s && break || echo "Waiting for Keda..."; sleep 30; done

# Display ArgoCD password and ingress information
echo "-----------------"
echo "ArgoCD Admin pass"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
echo "Ingress public IP"
kubectl get svc ingress-nginx-controller --namespace ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Install Keda features
kubectl apply -f ../services/keda/keda-dash.yml
kubectl apply -f ../services/keda/service_monitor.yml

set +e
# Add metrics and Vault injector ports to EKS ingress security group
EKS_SG=`aws eks describe-cluster --name $TF_VAR_name-eks --query 'cluster.resourcesVpcConfig.clusterSecurityGroupId' --output text`
NODE_SG=`aws ec2 describe-instances --filter "Name=tag:eks:cluster-name,Values=$TF_VAR_name-eks" --query Reservations[*].Instances[*].NetworkInterfaces[0].Groups[0].GroupId --output text | head -n1 | awk '{print $1;}'`
aws ec2 authorize-security-group-ingress --group-id $NODE_SG --protocol tcp --port 6443 --source-group $EKS_SG
aws ec2 authorize-security-group-ingress --group-id $NODE_SG --protocol tcp --port 4443 --source-group $EKS_SG
aws ec2 authorize-security-group-ingress --group-id $NODE_SG --protocol tcp --port 8080 --source-group $EKS_SG

