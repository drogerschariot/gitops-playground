#!/bin/bash

set -e

# Get Platform
PLATFORM="$(uname -s)"
case "${PLATFORM}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    MSYS_NT*)   machine=Git;;
    *)          machine="UNKNOWN:${PLATFORM}"
esac

# Grab Azure env variables
if [[  ! -z "${IS_GITHUB_ACTIONS}" ]]; then
  echo "Using Actions ENVs"
else
  source .env
fi

echo "Running Terraform..."
terraform init
terraform apply -auto-approve

echo "Fetching AKS creds for kubectl"
az aks get-credentials --resource-group $TF_VAR_name --name $TF_VAR_name-k8s --overwrite-existing

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
kubectl apply -f ../argocd/cert-manager/cluster-issuer.yml
kubectl apply -f ../argocd/argocd/prom.yml --namespace argocd
kubectl apply -f ../argocd/argocd/keda.yml --namespace argocd

sleep 30 #wait for ArgoCD to create namespace

echo "Waiting for Nginx Controller to install..."
for i in {1..10}; do kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=controller  --namespace ingress --timeout=240s && break || echo "Waiting for ingress controller..."; sleep 30; done

echo "Waiting for Cert Manager install..."
for i in {1..10}; do kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=cert-manager --namespace cert-manager --timeout=240s && break || echo "Waiting for cert-manager..."; sleep 30; done

echo "Waiting for Prometheus"
for i in {1..10}; do kubectl wait --for=condition=ready pod -l app=kube-prometheus-stack-operator --namespace monitoring --timeout=240s && break || echo "Waiting for prometheus..."; sleep 30; done

echo "Waiting for Keda"
for i in {1..10}; do kubectl wait --for=condition=ready pod -l app=keda-operator --namespace keda --timeout=240s && break || echo "Waiting for Keda..."; sleep 30; done

# Install Keda features
kubectl apply -f ../services/keda/keda-dash.yml
kubectl apply -f ../services/keda/service_monitor.yml

echo "\n\n-----------------"
echo "ArgoCD Admin pass"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
echo "Ingress public IP"
kubectl get svc ingress-nginx-controller --namespace ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
echo ""

# Install Vault and Consul
cd ../services/vault/
./vault-up.sh 
