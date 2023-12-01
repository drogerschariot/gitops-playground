#!/bin/bash

set -e

#Check if base install script was run and ArgoCD exists
if [ "`kubectl get pods -l app.kubernetes.io/name=argocd-server -o jsonpath='{.items[*].status.containerStatuses[0].ready}' --namespace argocd`" != "true" ]; then
  echo "It seems the base install script was not run. Please follow https://github.com/drogerschariot/gitops-playground#install"
  exit 1
fi

echo "Installing Redis Cluster"
kubectl apply -f redis-cluster.yml
sleep 60
for i in {1..10}; do kubectl wait --for=condition=ready pod -l statefulset.kubernetes.io/pod-name=redis-cluster-0 -n redis-cluster --timeout=600s && break || echo "Waiting for Redis Cluster..."; sleep 30; done


echo "Installing Redis Grafana Dashboard..."
kubectl apply -f redis-dash.yml
