#!/bin/bash

source .env

echo "Destroying Load Balancer..."
kubectl delete -f ../argocd/argocd/nginx-ingress.yml --namespace argocd
kubectl delete namespace ingress

echo "------------"
echo "We are about to run terraform destroy. Make sure you are running this script in the gitops-playground/aws-infra directory."
sleep 10
terraform destroy