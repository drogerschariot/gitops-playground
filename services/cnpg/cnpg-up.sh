#!/bin/bash

#Check if base install script was run and ArgoCD exists
if [ "`kubectl get pods -l app.kubernetes.io/name=argocd-server -o jsonpath='{.items[*].status.containerStatuses[0].ready}' --namespace argocd`" != "true" ]; then
  echo "It seems the base install script was not run. Please follow https://github.com/drogerschariot/gitops-playground#install"
  exit 1
fi

echo "Installing CNPG"
kubectl apply -f ../../argocd/argocd/cnpg.yml
sleep 30
kubectl -n cnpg-system wait --for condition=established --timeout=60s crd/clusters.postgresql.cnpg.io
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=cloudnative-pg --namespace cnpg-system --timeout=60s
echo "Installing test cluster"
kubectl apply -f cnpg.yml
sleep 30

for i in {1..10}; do kubectl wait --for=condition=ready pod -l cnpg.io/instanceName=test-db-1 --namespace default && break || echo "Waiting for Cluster to start..."; sleep 30; done
echo "Installing DNPG Grafana Dashboard..."
kube apply -f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/main/docs/src/samples/monitoring/grafana-configmap.yaml
