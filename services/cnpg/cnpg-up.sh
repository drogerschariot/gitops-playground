#!/bin/bash

echo "Installing CNPG"
kubectl apply -f ../../argocd/argocd/cnpg.yml
kubectl apply -f cnpg.yml