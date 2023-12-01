#!/bin/bash

set -e

echo "Installing JFrog Artifactory OSS..."
kubectl apply -f artifactory-oss.yml
sleep 60

# Wait for pods to become Ready
for i in {1..10}; do kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=postgresql --namespace artifactory-oss --timeout=600s && break || echo "Waiting for Artifactory..."; sleep 30; done
for i in {1..10}; do kubectl wait --for=condition=ready pod -l role=artifactory --namespace artifactory-oss --timeout=600s && break || echo "Waiting for Artifactory..."; sleep 30; done
