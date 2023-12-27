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

for i in {1..10}; do kubectl wait --for=condition=ready pod -l cnpg.io/instanceName=test-db-1 --namespace test-db --timeout=600s && break || echo "Waiting for Cluster to start..."; sleep 30; done
echo "Installing DNPG Grafana Dashboard..."
kubectl apply -f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/main/docs/src/samples/monitoring/grafana-configmap.yaml --namespace monitoring
