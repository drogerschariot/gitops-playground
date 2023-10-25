# gitops-playground

Spin up a K8s cluster in AWS or Azure for testing ArgoCD Applications, services, etc in a real world kubernetes environment. Base script will install:
- [ArgoCD](https://argo-cd.readthedocs.io/en/stable/)
- [Nginx ingress controller](https://github.com/kubernetes/ingress-nginx)
- [Prometheus with Grafana](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [Cert Manager](https://cert-manager.io/)
- [Keda](https://keda.sh/)
- [K8s Metrics Server](https://github.com/kubernetes-sigs/metrics-server)

## AWS

### Requirements

- [AWS cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)

### Install 
1. `git clone https://github.com/drogerschariot/gitops-playground.git`
2. `cd gitops-playground/aws-infra/`
3. Copy example env file `cp aws-env .env` Edit the `.env` file and update environment variables.
4. Run script `./aws-up.sh`

The script will run terraform to install required k8s infrastructure, install services, EBS CSI driver, and add kubernetes context. You will see the ArgoCD password and ingress public IP at the end of the output.

After you install the script, the kubernetes context will be automatically installed. See `kubectl config get-contexts` You can access the cluster using apps like [K9s](https://k9scli.io/) or [Lens](https://k8slens.dev/). 

## Azure

### Requirements

- [Azure cli](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)

### Install 
1. `git clone https://github.com/drogerschariot/gitops-playground.git`
2. `cd gitops-playground/azure-infra/`
3. Copy example env file `cp azure-env .env` Edit the `.env` file and update environment variables.
3. Login to Azure `az login`
4. Run script `./azure-up.sh`

The script will run terraform to install required k8s infrastructure, install services, and add kubernetes context. You will see the ArgoCD password and ingress public IP at the end of the output.

After you install the script, the kubernetes context will be automatically installed. See `kubectl config get-contexts` You can access the cluster using apps like [K9s](https://k9scli.io/) or [Lens](https://k8slens.dev/). 

## Access

### Local

- ArgoCD (http://localhost:8080/): `kubectl port-forward deployment/argocd-server 8080:8080 --namespace argocd`
- Grafana (http://localhost:3000/): `kubectl port-forward deployment/kube-prometheus-stack-grafana 3000:3000 --namespace monitoring`
- Prometheus: (http://localhost:9090): `kubectl port-forward svc/kube-prometheus-stack-prometheus 9090:http-web --namespace monitoring`

## Services
The following service are available to install and test. Click on the link to access install instructions.
- [CloudNativePG](https://github.com/drogerschariot/gitops-playground/blob/main/services/cnpg/README.md)

## Teardown

### AWS 
- `cd gitops-playground/aws-infra/`
- `./aws-down.sh`

### Azure 
- `cd gitops-playground/azure-infra/`
- `./azure-down.sh`
