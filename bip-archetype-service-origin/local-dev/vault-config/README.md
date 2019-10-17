# Vault Configuration Docker Image
Container to configures Vault for the Consul secret backend.

__THIS IS FOR LOCAL DEVELOPMENT ONLY AS SUPPLYING ACL TOKEN VIA ENVIRONMENT VARIABLES IS NOT SECURE__

## Configuring the container
The following environment variables are used to configure the container:
* `VAULT_ADDR` - Vault service endpoint. Required.
* `VAULT_DEV_ROOT_TOKEN` - Vault root token. Required.
* `CONSUL_HTTP_ADDR` - Consul service endpoint. Required.
* `CONSUL_HTTP_TOKEN` - ACL Token that Vault should use to authenticate with Consul. Required.

### Example docker-compose file
```yaml
version: "3.3"
services:
    vault-config:
        image: ocpdev/vault-config
        environment:
        - VAULT_ADDR=http://vault:8200
        - VAULT_DEV_ROOT_TOKEN_ID=vaultroot
        - CONSUL_HTTP_ADDR=http://consul:8500
        - CONSUL_HTTP_TOKEN=7652ba4c-0f6e-8e75-5724-5e083d72cfe4
```
