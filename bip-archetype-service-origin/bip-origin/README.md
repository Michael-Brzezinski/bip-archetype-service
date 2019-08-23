## What is this repository for?
This project is the service application module for the Origin project to expose a REST API, validate and process requests, and call external partners.

## About the service application
The service application consists of:
- The configuration elements to connect to Vault and Consul, boot strap Spring Boot, and configure the platform capabilities for the application.
- Exposure of an API with request validation and exception management.
- Service capabilities to process requests and acquire data from external partners.

The responsibilities and capabilities of the service application are :exclamation:add information here:exclamation:.

## How to add the dependency
The service application project is one of the sub-project `<modules>` in a reactor project.  Add the service project to the reactor POM.
```xml
	<module>bip-origin</module>
```

## Diagrams

#### Class Diagram
:exclamation:add class diagrams to /docs/images, and add html img tags to refer to them:exclamation:

#### Sequence Diagrams

:exclamation:add sequence diagrams to /docs/images, and add html img tags to refer to them:exclamation:

