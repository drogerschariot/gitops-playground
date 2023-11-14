#!/bin/bash

set -e

#Check if base install script was run and ArgoCD exists
if [ "`kubectl get pods -l app.kubernetes.io/name=argocd-server -o jsonpath='{.items[*].status.containerStatuses[0].ready}' --namespace argocd`" != "true" ]; then
  echo "It seems the base install script was not run. Please follow https://github.com/drogerschariot/gitops-playground#install"
  exit 1
fi

echo "Installing Otelm"
kubectl apply -f otelm.yml
sleep 30
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=opentelemetry-operator -n otelm-operator --timeout=300s
sleep 30

