#!/bin/bash

# Grab Azure env variables
if [[  ! -z "${IS_GITHUB_ACTIONS}" ]]; then
  echo "Using Actions ENVs"
else
  source ../../aws-infra/.env
fi

helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter --version "${KARPENTER_VERSION}" --namespace "${KARPENTER_NAMESPACE}" --create-namespace \
  --set "settings.clusterName=${CLUSTER_NAME}" \
  --set "settings.interruptionQueue=${CLUSTER_NAME}" \
  --set controller.resources.requests.cpu=1 \
  --set controller.resources.requests.memory=1Gi \
  --set controller.resources.limits.cpu=1 \
  --set controller.resources.limits.memory=1Gi \
  --wait

envsubst < node-pool.yaml| kubectl apply -f -

echo "To Run tests:"
echo "kubectl scale deployment inflate --replicas 0"
echo "kubectl logs -f -n "${KARPENTER_NAMESPACE}" -l app.kubernetes.io/name=karpenter -c controller"