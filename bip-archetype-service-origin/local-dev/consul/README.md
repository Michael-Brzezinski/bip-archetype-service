# Consul Docker Image
Custom Consul image that adds the ability to configure an ACL token via Environment variable.

__THIS IS FOR LOCAL DEVELOPMENT ONLY AS SUPPLYING ACL TOKEN VIA ENVIRONMENT VARIABLES IS NOT SECURE__

## Configuring the container
The container can be configured with an ACL token by setting the `MASTER_ACL_TOKEN` environment variable.

All other configuration options can be found in the documentation for the [Official Consul Image](https://hub.docker.com/_/consul).

### Example docker-compose file
```yaml
version: "3.3"
services:
    consul:
        image: ocpdev/consul:1.4.3
        environment:
        - MASTER_ACL_TOKEN=7642ba4c-0f6e-8e75-5725-5e083d72cfe4
        ports:
        - "8500:8500"
```
