#!/bin/bash

set -e

#Check if base install script was run and ArgoCD exists
if [ "`kubectl get pods -l app.kubernetes.io/name=argocd-server -o jsonpath='{.items[*].status.containerStatuses[0].ready}' --namespace argocd`" != "true" ]; then
  echo "It seems the base install script was not run. Please follow https://github.com/drogerschariot/gitops-playground#install"
  exit 1
fi

kubectl apply -f jenkins.yml

#for i in {1..10}; do kubectl wait --for=condition=ready pod -l app=wazuh-indexer --namespace wazuh --timeout=600s && break || echo "Waiting for Cluster to start..."; sleep 30; done
