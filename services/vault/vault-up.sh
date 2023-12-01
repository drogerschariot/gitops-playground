#!/bin/bash
# Clean up
rm -r tls

set -e

mkdir tls
echo "Installing Consul..."
kubectl apply -f consul.yml
sleep 30

echo "Installing and bootstrapping Vault..." 
# Install CF SSL
curl -L https://github.com/cloudflare/cfssl/releases/download/v1.6.1/cfssl_1.6.1_linux_amd64 -o ./cfssl && \
curl -L https://github.com/cloudflare/cfssl/releases/download/v1.6.1/cfssljson_1.6.1_linux_amd64 -o ./cfssljson && \
chmod +x ./cfssl && \
chmod +x ./cfssljson

echo "Generating TLS..."
./cfssl gencert -initca ca-csr.json | ./cfssljson -bare tls/ca
./cfssl gencert \
  -ca=tls/ca.pem \
  -ca-key=tls/ca-key.pem \
  -config=ca-config.json \
  -hostname="vault,vault.vault.svc.cluster.local,vault.vault.svc,localhost,127.0.0.1" \
  -profile=default \
  ca-csr.json | ./cfssljson -bare tls/vault

kubectl -n vault create secret tls tls-ca \
 --cert ./tls/ca.pem  \
 --key ./tls/ca-key.pem

kubectl -n vault create secret tls tls-server \
  --cert ./tls/vault.pem \
  --key ./tls/vault-key.pem

echo "Installing Vault..."
kubectl apply -f vault.yml
sleep 60

for i in {1..10}; do kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=vault --namespace vault --timeout=600s && break || echo "Waiting for Vault..."; sleep 30; done

echo -e "\n\n Unsealing Vault..."
kubectl -n vault exec -it vault-0 -- vault operator init > vault.creds

# Grab 5 unseal keys
keys=()
for i in `head -5 vault.creds | cut -d ' ' -f 4 | sed 's/\r$//' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g"`; do keys+=("$i"); done;

# Get root token
root_token=`sed '7!d' vault.creds | cut -d ' ' -f 4 | sed 's/\r$//' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g"`

# Unseal
for i in "${keys[@]}"
do
  if [[ `kubectl -n vault exec -it vault-0 -- vault status` ]];
  then
    kubectl -n vault exec -it vault-0 -- vault operator unseal "$i"
    sleep 5
  fi
done

for i in "${keys[@]}"
do
  if [[ `kubectl -n vault exec -it vault-1 -- vault status` ]];
  then
    kubectl -n vault exec -it vault-1 -- vault operator unseal $i
    sleep 5
  fi
done

# Enable kubernetes auth
for i in {1..10}; do kubectl wait --for=condition=ready pod -l component=server --namespace vault --timeout=600s && break || echo "Waiting for Vault..."; sleep 30; done
echo "Waiting for clients to unseal..."
sleep 60 # wait for clients to unseal
kubectl -n vault exec -it vault-0 -- vault login $root_token
kubectl -n vault exec -it vault-0 -- vault auth enable kubernetes
kubectl -n vault exec -it vault-0 -- sh -c 'vault write auth/kubernetes/config token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" kubernetes_host=https://${KUBERNETES_PORT_443_TCP_ADDR}:443 kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt issuer="https://kubernetes.default.svc.cluster.local"'

echo -e "\n\n---------------------"
echo -e "Vault creds are:\n\n"
cat vault.creds