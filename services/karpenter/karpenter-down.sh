#!/bin/bash

# Grab Azure env variables
if [[  ! -z "${IS_GITHUB_ACTIONS}" ]]; then
  echo "Using Actions ENVs"
else
  source ../../aws-infra/.env
fi

kubectl delete deployment inflate

helm uninstall karpenter --namespace "${KARPENTER_NAMESPACE}"
aws ec2 describe-launch-templates --filters "Name=tag:karpenter.k8s.aws/cluster,Values=${CLUSTER_NAME}" |
    jq -r ".LaunchTemplates[].LaunchTemplateName" |
    xargs -I{} aws ec2 delete-launch-template --launch-template-name {}
