#!/bin/bash

set -e

#Check if base install script was run and ArgoCD exists
if [ "`kubectl get pods -l app.kubernetes.io/name=argocd-server -o jsonpath='{.items[*].status.containerStatuses[0].ready}' --namespace argocd`" != "true" ]; then
  echo "It seems the base install script was not run. Please follow https://github.com/drogerschariot/gitops-playground#install"
  exit 1
fi

echo "Installing Otelm Demo"
kubectl apply -f otelm-demo.yml
sleep 60
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=opentelemetry-demo-frontend -n otelm-demo --timeout=600s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n otelm-demo --timeout=600s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=otelcol -n otelm-demo --timeout=600s
sleep 60

