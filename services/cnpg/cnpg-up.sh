#!/bin/bash

#Check if base install script was run and ArgoCD exists
if [ "`kubectl get pods -l app.kubernetes.io/name=argocd-server -o jsonpath='{.items[*].status.containerStatuses[0].ready}' --namespace argocd`" != "true" ]; then
  echo "It seems the base install script was not run. Please follow https://github.com/drogerschariot/gitops-playground#install"
  exit 1
fi

echo "Installing CNPG"
kubectl apply -f ../../argocd/argocd/cnpg.yml
sleep 10
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=cloudnative-pg --namespace cnpg-system 
kubectl apply -f cnpg.yml
