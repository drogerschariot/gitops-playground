#!/bin/bash

set -e

#Check if base install script was run and ArgoCD exists
if [ "`kubectl get pods -l app.kubernetes.io/name=argocd-server -o jsonpath='{.items[*].status.containerStatuses[0].ready}' --namespace argocd`" != "true" ]; then
  echo "It seems the base install script was not run. Please follow https://github.com/drogerschariot/gitops-playground#install"
  exit 1
fi

echo "Installing CNPG"
kubectl apply -f ../../argocd/argocd/cnpg.yml
sleep 60
kubectl -n cnpg-system wait --for condition=established crd/clusters.postgresql.cnpg.io --timeout=600s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=cloudnative-pg --namespace cnpg-system --timeout=600s
echo "Installing test cluster"
kubectl apply -f cnpg.yml
sleep 60

for i in {1..10}; do kubectl wait --for=condition=ready pod -l cnpg.io/instanceName=test-db-1 --namespace test-db --timeout=600s && break || echo "Waiting for Cluster to start..."; sleep 30; done
echo "Installing DNPG Grafana Dashboard..."
kubectl apply -f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.19/docs/src/samples/monitoring/grafana-configmap.yaml --namespace monitoring
