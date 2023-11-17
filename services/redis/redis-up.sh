#!/bin/bash

set -e

#Check if base install script was run and ArgoCD exists
if [ "`kubectl get pods -l app.kubernetes.io/name=argocd-server -o jsonpath='{.items[*].status.containerStatuses[0].ready}' --namespace argocd`" != "true" ]; then
  echo "It seems the base install script was not run. Please follow https://github.com/drogerschariot/gitops-playground#install"
  exit 1
fi

echo "Installing Redis"
kubectl apply -f redis.yml
sleep 60
kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=master -n redis --timeout=600s
sleep 60

echo "Installing Redis Grafana Dashboard..."
kubectl apply -f redis-dash.yml
