FROM vault

ARG CONSUL_VERSION=1.4.2
ARG JQ_VESRION=1.6

# Install Curl
RUN apk add --no-cache curl

# Install Consul
ADD https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip consul.zip
RUN unzip consul.zip; \
    mv consul /usr/local/bin/consul; \
    chmod +x /usr/local/bin/consul; \
    rm -f consul.zip

# Instal jq
ADD https://github.com/stedolan/jq/releases/download/jq-${JQ_VESRION}/jq-linux64 /usr/bin/jq
RUN chmod 755 /usr/bin/jq

ADD vault-config.sh /vault-config.sh
ADD token-policy.hcl /token-policy.hcl
RUN mkdir -p /consul
ADD consul /consul
RUN mkdir -p /vault
ADD vault /vault

ENTRYPOINT ["/vault-config.sh"]