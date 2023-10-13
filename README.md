# gitops-playground

Spin up a K8s cluster in Azure to test out ArgoCD Apps.

## Auth
1. Login using `az login`. This resource group will use Chariot's [Microsoft Partner Network](https://portal.azure.com/#@chariotsolution.onmicrosoft.com/resource/subscriptions/6380d0fa-5d0c-4239-8302-3f40269c2e9c/overview)

## Sping up AKS cluster
1. `cd azure-infra`
2. `terraform apply`
3. `az aks get-credentials --resource-group gitops-playground --name gitops-k8s`

## Install ArgoCD
- `helm repo add argo https://argoproj.github.io/argo-helm`
- `kubectl create namespace argocd` 
- `helm install argocd argo/argo-cd --namespace argocd`
- `kubectl apply -f argocd/argocd/repos.yaml --namespace argocd`
- `kubectl apply -f argocd/argocd/github-connector.yaml --namespace argocd`
- Get Admin password: `kubectl -n default get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`
- Open svc port to admin GUI using K9s or kubectl.

## Add ArgoCD Apps
Any Application CRD should be added to `/argocd` eg `./argocd/guestbook`
- Create the application in ArgoCD GUI, and example would be the guestbook app which looks like this:
![image](https://github.com/chariotsolutions/gitops-playground/assets/1655964/41c6cdb5-18a6-49d7-9583-07c3c9412726)

## WARNING
The gitops-playground resource group will self distruct every night.
