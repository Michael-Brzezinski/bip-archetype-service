# Local Development Environment

This local development environment is strictly for demonstration and local testing of the BIP Platform and Services.

The local-dev folder also contains tools to assist with preparing to submit [SwA Code Reviews](../docs/fortify-and-swa.md).

For information about the BIP Framework and Reference Application, see this [README](https://github.ec.va.gov/EPMO/bip-reference-person).

## Starting the Environment

To start the environment first build the BIP origin service by running `mvn clean package`. The platform can then be started by running `docker-compose up -d --build`.

## Service Links

The `bip-origin` spring boot app must be running for these links to be accessible.

- [BIP Origin App](http://localhost:8080)
- [Consul](http://localhost:8500) - Master ACL token is `7652ba4c-0f6e-8e75-5724-5e083d72cfe4`
- [Vault](http://localhost:8200) - Root token is `vaultroot`
- [Prometheus](http://localhos:9090)
- [Grafana](http://localhost:3000) - Username/Password is `admin/admin` by default

## Clearing the Redis Cache

By default, the RedisEmbeddedServer will be spun up in a docker instance. Appropriate configuration in the application YAML allows the framework to connect to the server.

As a developer, there may be instances when you need to make calls that do not retrieve from the cache (for example, when testing parter calls from the swagger UI).

There are 3 ways you can clear the cache:

#### 1. In any Spring Profile:

The cache auto-configuration registers `BipCacheOpsMBean` and its implementation as a spring JMX management bean (enabled by the `@EnableMBeanExport` annotation). This bean allows developers to clear the cache on the fly when testing code that must bypass the cache, and can be enhanced to provide other cache management activities. Usage of this bean is:

1. Start the spring boot service app (in STS or from command line)
2. Open `$JAVA_HOME/bin/jconsole` (JAVA_HOME must point to a full JDK, not SE, as jconsole is only available in the full JDK)
3. When jconsole opens:
  - In the _New Connection_ dialog, select _Local Process > gov.va.bip.person.OriginApplication_ and click the _Connect_ button
  - If asked, allow _Insecure connection_
  - When the console comes up, select the _MBeans_ tab
  - In the list pane on the left, look under _gov.va.bip.cache > Support > cacheOps > Operations > clearAllCaches_, and click on the _clearAllCaches_ entry
  - In the right pane under _Operation Invocation_, click the _clearAllCaches()_ button
  - After a moment, a "Method successfully invoked" message should pop up, indicating that all cache entries have been cleared

#### 2. Default Profile:

If you run the app in default profile, it uses emebedded redis server for caching. To clear cache, follow the below steps.

- Download [Redis](https://redis.io/download)
- Go to src folder and run `redis-cli`
- To see the cache entries - `KEYS *`
- To clear cache entries - `FLUSHALL`

#### 3. local-int profile:

If you run the app in local-int (docker) profile, follow the below steps.

- Find the container id of the redis using `docker ps -a`
- Log into the container `docker exec -i -t <container-id> sh`
- Enter `redis-cli`
- To see the cache entries - `KEYS *`
- To clear cache entries - `FLUSHALL`
