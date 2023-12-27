#!/bin/bash

set -e

#Check if base install script was run and ArgoCD exists
if [ "`kubectl get pods -l app.kubernetes.io/name=argocd-server -o jsonpath='{.items[*].status.containerStatuses[0].ready}' --namespace argocd`" != "true" ]; then
  echo "It seems the base install script was not run. Please follow https://github.com/drogerschariot/gitops-playground#install"
  exit 1
fi

echo "Installing Elasticsearch"
kubectl apply -f elastic-stack.yml
sleep 60

for i in {1..10}; do kubectl wait --for=condition=ready pod -l statefulset.kubernetes.io/pod-name=elasticsearch-data-0 --namespace elasticsearch --timeout=600s && break || echo "Waiting for Cluster to start..."; sleep 30; done
for i in {1..10}; do kubectl wait --for=condition=ready pod -l statefulset.kubernetes.io/pod-name=elasticsearch-master-0 --namespace elasticsearch --timeout=600s && break || echo "Waiting for Cluster to start..."; sleep 30; done
for i in {1..10}; do kubectl wait --for=condition=ready pod -l statefulset.kubernetes.io/pod-name=elasticsearch-ingest-0 --namespace elasticsearch --timeout=600s && break || echo "Waiting for Cluster to start..."; sleep 30; done
for i in {1..10}; do kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=metrics --namespace elasticsearch --timeout=600s && break || echo "Waiting for Cluster to start..."; sleep 30; done

echo "Installing Elasticsearch Grafana Dashboard..."
kubectl apply -f es-dashboard.yml
