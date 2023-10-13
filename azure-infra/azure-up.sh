#!/bin/bash

# Grab Azure env variables
source ./env

echo "Running Terraform..."
terraform apply -auto-approve

echo "Fetching AKS creds for kubectl"
az aks get-credentials --resource-group $TF_VAR_name --name $TF_VAR_name-k8s --overwrite-existing

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

echo "Installing nginx-ingress and cert-manager ArgoCD Applications"
kubectl apply -f ../argocd/argocd/nginx-ingress.yml --namespace argocd
kubectl apply -f ../argocd/argocd/cert-manager.yaml --namespace argocd

echo "Waiting for Applications to install...
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=ingress-nginx --namespace ingress
echo "ArgoCD Admin pass"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
echo "Ingress public IP"
kubectl get svc ingress-nginx-controller --namespace ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}'