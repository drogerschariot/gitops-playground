#!/bin/bash

set -e

#Check if base install script was run and ArgoCD exists
if [ "`kubectl get pods -l app.kubernetes.io/name=argocd-server -o jsonpath='{.items[*].status.containerStatuses[0].ready}' --namespace argocd`" != "true" ]; then
  echo "It seems the base install script was not run. Please follow https://github.com/drogerschariot/gitops-playground#install"
  exit 1
fi

echo "Installing Gitlab Operator..."
kubectl apply -f gitlab.yml
sleep 60
for i in {1..10}; do kubectl wait --for=condition=ready pod -l control-plane=controller-manager --namespace gitlab --timeout=600s && break || echo "Waiting for Cluster to start..."; sleep 30; done

echo "Install Test Gitlab..."
kubectl apply -f test-lab.yml
sleep 60
for i in {1..10}; do kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=gitlab-webservice --namespace gitlab --timeout=600s && break || echo "Waiting for Cluster to start..."; sleep 30; done

echo "Install service monitor..."
kubectl apply -f service_monitor.yml
