#!/bin/bash

set -e

echo "Installing JFrog Platform..."
kubectl apply -f jfrog-platform.yml
sleep 60

# Wait for pods to become Ready
for i in {1..10}; do kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=postgresql --namespace jfrog-platform --timeout=600s && break || echo "Waiting for JFrog Platform..."; sleep 30; done
for i in {1..10}; do kubectl wait --for=condition=ready pod -l component=nginx --namespace jfrog-platform --timeout=600s && break || echo "Waiting for JFrog Artifactory..."; sleep 30; done
for i in {1..10}; do kubectl wait --for=condition=ready pod -l component=artifactory --namespace jfrog-platform --timeout=600s && break || echo "Waiting for JFrog Artifactory..."; sleep 30; done
for i in {1..10}; do kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=vault --namespace jfrog-platform --timeout=600s && break || echo "Waiting for JFrog Artifactory..."; sleep 30; done
for i in {1..10}; do kubectl wait --for=condition=ready pod -l component=xray --namespace jfrog-platform --timeout=600s && break || echo "Waiting for JFrog Artifactory..."; sleep 30; done
