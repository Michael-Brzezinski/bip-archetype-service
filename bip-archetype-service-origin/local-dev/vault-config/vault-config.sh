#! /bin/sh
echo "Configuring Vault..."

# Wait up to 60 seconds for Vault to be available
until $(curl -XGET --insecure --fail --output /dev/null --silent -H "X-Vault-Token: $VAULT_TOKEN" $VAULT_ADDR/v1/sys/health); do
    echo "Waiting for Vault to be available..."
    sleep 10
done

# Authenticate to Vault
vault login $VAULT_DEV_ROOT_TOKEN_ID

#################### Enable Consul Secret Backend ####################
vault secrets enable consul

# Retrieve ACL token from Consul
ACL_TOKEN=$(curl -ks \
    --header "X-Consul-Token: ${CONSUL_HTTP_TOKEN}" \
    --request PUT \
    --data '{"Name": "sample", "Policies": [{"name": "global-management"}]}' \
    ${CONSUL_HTTP_ADDR}/v1/acl/token | jq -r .SecretID)

vault write consul/config/access \
    address=${CONSUL_HTTP_ADDR} \
    token=${ACL_TOKEN}

# Create Token Policy
consul acl policy create  -name "readonly" -description "Read Only Policy" -rules @/token-policy.hcl

# Configure Role Mapping
vault write consul/roles/os-svc policies=readonly

# Create Sample Properties in Consul
consul kv put config/bip-origin.yml @/consul/bip-origin.yml
consul kv put config/application.yml @/consul/application.yml

# Load a certificate credential example in Vault
echo "Loading Secrets into Vault..."
vault kv put secret/blue/bip-origin test=blah
vault kv put secret/blue/bip-origin/example-service \
    bip-origin-partner-person.ws.client.privateKey=@/vault/example.key \
    bip-origin-partner-person.ws.client.publicCert=@/vault/example.crt \
    bip-origin-partner-person.ws.client.trustedCerts.ca=@/vault/example.crt

######################################################################
