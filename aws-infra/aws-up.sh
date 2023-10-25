#!/bin/bash

# Grab Azure env variables
source .env

echo "Running Terraform..."
terraform init
terraform apply -auto-approve

echo "Fetching AKS creds for kubectl"
aws eks update-kubeconfig --region $TF_VAR_region --name $TF_VAR_name-eks

echo "Installing ArgoCD"
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for argocd to install..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server --namespace argocd

# Patch insecure flag to argocd server
kubectl patch deploy argocd-server --namespace argocd --type='json' \
  -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/args", "value": [
  "/usr/local/bin/argocd-server",
  "--insecure"
]}]'
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server --namespace argocd

echo "Installing nginx-ingress, cert-manager, and Prometheus ArgoCD Applications"
kubectl apply -f ../argocd/argocd/nginx-ingress.yml --namespace argocd
kubectl apply -f ../argocd/argocd/cert-manager.yaml --namespace argocd
kubectl apply -f ../argocd/argocd/prom.yml --namespace argocd
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

echo "Waiting for Applications to install..."
sleep 30 #wait for ArgoCD to create namespace
for i in {1..10}; do kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=ingress-nginx --namespace ingress && break || echo "Waiting for ingress controller..."; sleep 30; done
for i in {1..10}; do kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=cert-manager --namespace cert-manager && break || echo "Waiting for ingress cert-manager..."; sleep 30; done
#for i in {1..10}; do kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=cert-manager --namespace cert-manager && break || echo "Waiting for ingress cert-manager..."; sleep 30; done

echo "-----------------"
echo "ArgoCD Admin pass"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
echo "Ingress public IP"
kubectl get svc ingress-nginx-controller --namespace ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Add metrics port to EKS ingress security group
EKS_SG=`aws eks describe-cluster --name $TF_VAR_name-eks --query 'cluster.resourcesVpcConfig.clusterSecurityGroupId' --output text`
NODE_SG=`aws ec2 describe-instances --filter "Name=tag:eks:cluster-name,Values=$TF_VAR_name-eks" --query Reservations[*].Instances[*].NetworkInterfaces[0].Groups[0].GroupId --output text | tail -1`
aws ec2 authorize-security-group-ingress --group-id $NODE_SG --protocol tcp --port 4443 --source-group $EKS_SG
