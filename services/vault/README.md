# [Vault](https://www.vaultproject.io/)

Secure, store, and tightly control access to tokens, passwords, certificates, and encryption keys for protecting secrets and other sensitive data using a UI, CLI, or HTTP API.

Vault and the Vault injector gets installed and unsealed automatically with the [base install](https://github.com/drogerschariot/gitops-playground#gitops-playground) script. Below is an example on how to inject secrets into your pod.

### Vault Access
After you run either the AWS or Azure install script, the vault credentials will be in a file called `vault.creds`. Use the root token to login.
```bash
$ kubectl -n vault port-forward svc/vault-ui 8200:8200
```

###  Vault Secret Injection Example
The following is an example of the components we need to inject secrets into our pods with the Vault injector. We will create:
- **Role**: A predefined set of permissions and policies that dictate the actions and access levels a user or system entity has withinVault, facilitating secure and controlled operations. 
- **Service Account**: The Kubernetes service attached to the pod
- **Vault Policy**: A set of rules and configurations that define access control for a logical group of secrets.

Run the following in the `service/vault` directory.

### Create Role
Create a role with a bound service account, namespace, and policy name:
```bash
$ kubectl -n vault exec -it vault-0 -- sh -c 'vault write auth/kubernetes/role/demo-injector bound_service_account_names=injector-sa bound_service_account_namespaces=default policies=injector-policy ttl=1h'
```

#### Create K8s Service
Create a role with a bound service account, namespace, and policy name:
```bash
$ kubectl apply -f service.yml
```
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: injector-sa
  labels:
    app: injector-sa
```

#### Create Vault policy
```bash
$ kubectl -n vault cp policy.hcp vault-0:/home/vault
$ kubectl -n vault exec -it vault-0 -- vault policy write injector-policy /home/vault/policy.hcp
```
```hcp
path "secret/too-many-secrets/*" {
  capabilities = ["read"]
}
```

#### Create Secret engine
Create a Secret engine called `secret` and add a secret called `fake_token`:
```bash
$ kubectl -n vault exec -it vault-0 -- vault secrets enable -path=secret/ kv
$ kubectl -n vault exec -it vault-0 -- vault kv put secret/too-many-secrets/fake_token token=9n81c3fncbhcasfy377234nasc
```

#### Create Example Deployment
Install the deployment. Take note of the `vault.hashicorp.com` annotations.
```bash
$ kubectl apply -f test-injector.yml
```
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-injector
  labels:
    app: test-injector
spec:
  selector:
    matchLabels:
      app: test-injector
  replicas: 1
  template:
    metadata:
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/tls-skip-verify: "true"
        vault.hashicorp.com/agent-inject-secret-fake_token: "secret/too-many-secrets/fake_token"
        vault.hashicorp.com/agent-inject-template-fake_token: |
          {{- with secret "secret/too-many-secrets/fake_token" -}}
          {
            "token" : "{{ .Data.token }}"
          }
          {{- end }}
        vault.hashicorp.com/role: demo-injector
      labels:
        app: test-injector
    spec:
      serviceAccountName: injector-sa
      containers:
      - name: test-injector
        image: nginx:1.25.3-alpine
```
The secret will be injected into the `/vault/secrets/` directory. You can `kubectl exec` into the test-injector pod and check the secret:
```bash
$ cat /vault/secrets/fake_token
{
  "token" : "9n81c3fncbhcasfy377234nasc"
}
```
