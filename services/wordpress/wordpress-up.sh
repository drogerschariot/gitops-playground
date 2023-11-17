#!/bin/bash

set -e

#Check if base install script was run and ArgoCD exists
if [ "`kubectl get pods -l app.kubernetes.io/name=argocd-server -o jsonpath='{.items[*].status.containerStatuses[0].ready}' --namespace argocd`" != "true" ]; then
  echo "It seems the base install script was not run. Please follow https://github.com/drogerschariot/gitops-playground#install"
  exit 1
fi

echo "Installing Wordpress"
kubectl apply -f wordpress.yml
sleep 60
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=mariadb -n wordpress --timeout=600s 
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=wordpress -n wordpress --timeout=600s
sleep 60

echo "-----------------"
echo "Wordpress Username: admin"
echo "Wordpress Password: `kubectl -n wordpress get secret wordpress -o jsonpath="{.data.wordpress-password}" | base64 -d; echo`"
echo "-----------------"
echo "Wordpress is using a self signed certificate so you will need to accept the security risk."
echo "Wordpress access https://`kubectl get svc/wordpress --namespace wordpress -o jsonpath='{.status.loadBalancer.ingress[0].ip}'`"
echo "Wordpress admin https://`kubectl get svc/wordpress --namespace wordpress -o jsonpath='{.status.loadBalancer.ingress[0].ip}'`/wp-admin"
