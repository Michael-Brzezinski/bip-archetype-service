## What is this repository for?

This is a suite of BIP projects for :exclamation:add project purpose here:exclamation:

BIP Framework has been updated to use the OpenAPI v3 "design first" approach to REST API declaration.
- Please review the [Framework Release Notes](https://github.ec.va.gov/EPMO/bip-framework/wiki/Framework-Release-Notes)
- If you are creating a new project, please see the [BIP OpenAPI v3 Developer Guide](docs/openapi-v3-developer-guide.md)
- If you are upgrading from BIP Framework 1.x to BIP Framework 2.x, please review the above links, and see the help at [Migrating from BIP Framework 1.x to BIP Framework 2.x](docs/openapi-v3-migration-guide.md).

# Project Breakdown

1. bip-origin-reactor: This is the root reactor project (you are in that repo now). This project forms the aggregate of modules that make up the complete service app, and manages the Fortify scans. In addition to its typical reactor duties, this project contains:
	- maven profiles and a `./fortify.sh` script to run Fortify
	- a local-dev folder with docker images to run in the spring "local-int" (docker) mode, and with tools to simplify SwA code review submissions.
	- a `template.yaml` file which is the Openshift deployment template used during the CI/CD pipeline for deployment.
	- a `testing.yaml` file which is used to configure the Helm Chart used by the CI/CD pipeline for the Kubernetes deployments.
	- a `Jenkinsfile` file which configures the CI/CD pipeline for the project. For more information on the CI/CD pipeline see the [Java Gitflow Pipeline](https://github.ec.va.gov/EPMO/bip-jenkins-lib/tree/master/docs/spring-boot-pipelines) and [Pipeline Configuration](https://github.ec.va.gov/EPMO/bip-jenkins-lib/blob/master/docs/spring-boot-pipelines/pipeline-config.md) documents.

2. :exclamation:add github URLs to any partner projects, and brief description here:exclamation:

3. [bip-origin](https://github.ec.va.gov/EPMO/__artifactId__/tree/master/__artifactId__): Service implementation project. This project :exclamation:description of project function:exclamation:. The design consists of three layers:

	- The Provider (or "web") layer contains the REST end-points and model, JSR 303 annotations in the resource class and the model, and the use of an adapter class to transform models and call the service interface. The end-points demonstrate use cases such that fetching some data based on a request, submitting data, file uploads and downloads.
	- The Domain (or "service") layer contains examples of business validation, business logic,  to call Partner services and process the returned data, and exception handling.
	- The Partner (or "client") layer shows how to perform model transformation, how to call a partner client interface, and how to handle responses (or exceptions thrown) from the partner client.

4. [bip-origin-inttest](https://github.ec.va.gov/EPMO/__artifactId__/tree/master/__artifactId__-inttest): Contains the integration tests using the framework Test Library Spring Rest Template, Cucumber libraries, and other capabilities). It includes functioning test cases that run against the service end-points.

5. [bip-origin-perftest](https://github.ec.va.gov/EPMO/__artifactId__/tree/master/__artifactId__-perftest): Contains performance JMX test scripts for Apache JMeter that run against the service endpoints.

For examples and documentation about how projects are structured, configured, and developed on the BIP Platform:

- [BIP Framework](https://github.ec.va.gov/EPMO/bip-framework)
- [BIP Reference - Person service](https://github.ec.va.gov/EPMO/bip-reference-person)

# Framework libraries in this project

The projects in this repository are dependent on the libraries from [BIP framework](https://github.ec.va.gov/EPMO/bip-framework) and [BIP framework test library](https://github.ec.va.gov/EPMO/bip-framework/tree/master/bip-framework-test-lib) for  auto configuration, common shared libraries, parent pom maven configuration and test libary.

1. `bip-framework-parentpom` is the parent of your application's parent (e.g. reactor) POM

2. The POM hierarchy for the application modules must resolve to the parent POM

3. Each module may add framework dependencies as needed

To make these libraries available for compilation, read [this section](#how-to-make-the-dependency-framework-libraries-available).

# How to build and test?

The fastest way to get set up is to visit the [Quick Start Guide](https://github.ec.va.gov/EPMO/bip-reference-person/blob/master/docs/quick-start-guide.md).


# Local Development
Instructions on running the application on a local workstation can be found in the [local-dev README](local-dev)

## Contribution guidelines
If you or your team wants to contribute to this repository, then fork the repository and follow the steps to create a PR for our upstream repo to review and commit the changes:
[Creating a pull request from a fork](https://help.github.com/articles/creating-a-pull-request-from-a-fork/)
