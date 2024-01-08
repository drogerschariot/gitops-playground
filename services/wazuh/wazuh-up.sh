#!/bin/bash
rm -rf wazuh-kubernetes 
set -e

# Reset deamonset file
cp daemonset.tmp daemonset.yml

#Check if base install script was run and ArgoCD exists
if [ "`kubectl get pods -l app.kubernetes.io/name=argocd-server -o jsonpath='{.items[*].status.containerStatuses[0].ready}' --namespace argocd`" != "true" ]; then
  echo "It seems the base install script was not run. Please follow https://github.com/drogerschariot/gitops-playground#install"
  exit 1
fi

git clone --depth 1 --branch v4.7.1 https://github.com/wazuh/wazuh-kubernetes.git
cd wazuh-kubernetes

MASTER_FILE="wazuh/wazuh_managers/wazuh-master-svc.yaml"
WORK_FILE="wazuh/wazuh_managers/wazuh-workers-svc.yaml"
INDEX_FILE="wazuh/indexer_stack/wazuh-indexer/cluster/indexer-api-svc.yaml"
DASH_FILE="wazuh/indexer_stack/wazuh-dashboard/dashboard-svc.yaml"
ANNOTATION_KEY="service.beta.kubernetes.io/aws-load-balancer-internal"
ANNOTATION_VALUE="0.0.0.0/0"
AZURE_ANNOTATION_KEY="service.beta.kubernetes.io/azure-load-balancer-internal"
AZURE_ANNOTATION_VALUE="true"

# Add internal annotation to svc
yq eval ".metadata.annotations += {\"$ANNOTATION_KEY\": \"$ANNOTATION_VALUE\"}" "$MASTER_FILE" > "$MASTER_FILE.tmp" \
  && mv "$MASTER_FILE.tmp" "$MASTER_FILE"
yq eval ".metadata.annotations += {\"$AZURE_ANNOTATION_KEY\": \"$AZURE_ANNOTATION_VALUE\"}" "$MASTER_FILE" > "$MASTER_FILE.tmp" \
  && mv "$MASTER_FILE.tmp" "$MASTER_FILE"
yq eval ".metadata.annotations += {\"$AZURE_ANNOTATION_KEY\": \"$ANNOTATION_VALUE\"}" "$WORK_FILE" > "$WORK_FILE.tmp" \
  && mv "$WORK_FILE.tmp" "$WORK_FILE"
yq eval ".metadata.annotations += {\"$ANNOTATION_KEY\": \"$ANNOTATION_VALUE\"}" "$DASH_FILE" > "$DASH_FILE.tmp" \
  && mv "$DASH_FILE.tmp" "$DASH_FILE"
yq eval ".metadata.annotations += {\"$AZURE_ANNOTATION_KEY\": \"$AZURE_ANNOTATION_VALUE\"}" "$DASH_FILE" > "$DASH_FILE.tmp" \
  && mv "$DASH_FILE.tmp" "$DASH_FILE"
yq eval -i '.metadata += {"annotations":{"service.beta.kubernetes.io/aws-load-balancer-internal":"0.0.0.0/0"}}' $INDEX_FILE
yq eval -i '.metadata.annotations += {"service.beta.kubernetes.io/azure-load-balancer-internal":"true"}' $INDEX_FILE
# Gen self signed certs
./wazuh/certs/indexer_cluster/generate_certs.sh
./wazuh/certs/dashboard_http/generate_certs.sh

# The Wazuh repo doesn't support Azure disk provisioner, so Azure is the cloud
# platform the storage-class.yaml will need to be updated.
while true; do
    echo -n "Cloud Platform: AWS or Azure? " 
    read cloud_provider

    case $cloud_provider in
        aws|AWS)
            break
            ;;
        azure|Azure)
            cp ../azure-storage-class.yml envs/eks/storage-class.yaml
            break
            ;;
        *)
            echo "Invalid input. Please enter 'aws' or 'azure'."
            ;;
    esac
done

# Apply Kustomize
echo "Installing Wazuh"
kubectl apply -k envs/eks/
sleep 60

for i in {1..10}; do kubectl wait --for=condition=ready pod -l app=wazuh-indexer --namespace wazuh --timeout=600s && break || echo "Waiting for Cluster to start..."; sleep 30; done
for i in {1..10}; do kubectl wait --for=condition=ready pod -l app=wazuh-manager --namespace wazuh --timeout=600s && break || echo "Waiting for Cluster to start..."; sleep 30; done
for i in {1..10}; do kubectl wait --for=condition=ready pod -l node-type=worker --namespace wazuh --timeout=600s && break || echo "Waiting for Cluster to start..."; sleep 30; done

# Add master and worker hosts to agent daemonset
cd ..

if [[ "$cloud_provider" == "Azure" || "$cloud_provider" == "azure" ]]; then
  MASTER=`kubectl get svc wazuh --namespace wazuh -o jsonpath='{.status.loadBalancer.ingress[0].ip}'`
  WORKER=`kubectl get svc wazuh-workers --namespace wazuh -o jsonpath='{.status.loadBalancer.ingress[0].ip}'`
else
  MASTER=`kubectl get svc wazuh --namespace wazuh -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'`
  WORKER=`kubectl get svc wazuh-workers --namespace wazuh -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'`
fi

sed -i '' "s/REPLACE_MASTER/$MASTER/" daemonset.yml
sed -i '' "s/REPLACE_WORKER/$WORKER/" daemonset.yml

# Install Wazuh Agent Daemonset
echo "Installing Wazuh Agent Daemonset..."
kubectl apply -f daemonset.yml
