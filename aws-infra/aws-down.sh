#!/bin/bash

# Grab Azure env variables
if [[  ! -z "${IS_GITHUB_ACTIONS}" ]]; then
  echo "Using Actions ENVs"
else
  source .env
fi

# Remove LB
echo "Destroying Load Balancer..."
kubectl delete -f ../argocd/argocd/nginx-ingress.yml --namespace argocd
kubectl delete svc/ingress-nginx-controller -n ingress

# Remove metrics port to EKS ingress security group
EKS_SG=`aws eks describe-cluster --name $TF_VAR_name-eks --query 'cluster.resourcesVpcConfig.clusterSecurityGroupId' --output text`
NODE_SG=`aws ec2 describe-instances --filter "Name=tag:eks:cluster-name,Values=$TF_VAR_name-eks" --query Reservations[*].Instances[*].NetworkInterfaces[0].Groups[0].GroupId --output text | head -n1 | awk '{print $1;}'`
aws ec2 revoke-security-group-ingress --group-id $NODE_SG --protocol tcp --port 6443 --source-group $EKS_SG
aws ec2 revoke-security-group-ingress --group-id $NODE_SG --protocol tcp --port 4443 --source-group $EKS_SG
aws ec2 revoke-security-group-ingress --group-id $NODE_SG --protocol tcp --port 8080 --source-group $EKS_SG

echo "------------"
echo "We are about to run terraform destroy. Make sure you are running this script in the gitops-playground/aws-infra directory."
sleep 10

terraform init

# Is running in Actions?
if [[  ! -z "${IS_GITHUB_ACTIONS}" ]]; then
  terraform destroy -auto-approve
else
  terraform destroy
fi

# Remove volumes
for i in `aws ec2 describe-volumes --filters "Name=tag:Name,Values=$TF_VAR_name*" --query "Volumes[*].{ID:VolumeId}" --output text` 
do
  aws ec2 delete-volume --volume-id $i
done
