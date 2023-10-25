#!/bin/bash

source .env

# Remove metrics port to EKS ingress security group
EKS_SG=`aws eks describe-cluster --name $TF_VAR_name-eks --query 'cluster.resourcesVpcConfig.clusterSecurityGroupId' --output text`
NODE_SG=`aws ec2 describe-instances --filter "Name=tag:eks:cluster-name,Values=$TF_VAR_name-eks" --query Reservations[*].Instances[*].NetworkInterfaces[0].Groups[0].GroupId --output text | tail -1`
aws ec2 revoke-security-group-ingress --group-id $NODE_SG --protocol tcp --port 4443 --source-group $EKS_SG


echo "Destroying Load Balancer..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl delete -f ../argocd/argocd/nginx-ingress.yml --namespace argocd
kubectl delete namespace ingress

echo "------------"
echo "We are about to run terraform destroy. Make sure you are running this script in the gitops-playground/aws-infra directory."
sleep 10
terraform destroy
