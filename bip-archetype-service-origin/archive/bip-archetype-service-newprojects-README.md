# What is this repository for?

This is a suite of BIP projects for :exclamation:add project purpose here:exclamation:


# Project Breakdown

1. :exclamation:add github URLs to any partner projects, and brief description here:exclamation:

2. [bip-origin](https://github.ec.va.gov/EPMO/__artifactId__/tree/master/__artifactId__): Service implementation project. This project :exclamation:description of project function:exclamation:. The design consists of three layers:

  - The Provider (or "web") layer contains the REST endpoints and model, JSR 303 annotations in the resource class and the model, and the use of an adapter class to transform models and call the service interface.
  - The Domain (or "service") layer contains business validation, business logic, client helpers to call Partner services and process the returned data, and exception handling.
  - The Partner (or "client") layer performs partner client model transformation, calls to partner client interfaces, and response handling.

3. [bip-origin-inttest](https://github.ec.va.gov/EPMO/__artifactId__/tree/master/__artifactId__-inttest): Contains the integration tests using the framework Test Library (Spring Rest Template, Cucumber libraries, and other capabilities). It includes test cases that run against the service endpoints.

4. [bip-origin-perftest](https://github.ec.va.gov/EPMO/__artifactId__/tree/master/__artifactId__-perftest): Contains performance JMX test scripts for Apache JMeter that run against the service endpoints.

For examples and documentation about how projects are structured, configured, and developed on the BIP Platform:

- [BIP Framework](https://github.ec.va.gov/EPMO/bip-framework)
- [BIP Reference - Person service](https://github.ec.va.gov/EPMO/bip-reference-person)

This project is dependent on the libraries from BIP framework a.k.a Blue for auto configuration, common shared libraries, parent pom maven configuration and functional testing library. These framework artifacts are included in the pom.xml files of the origin project modules.

The versions for the configured BIP Framework can be reviewed in the following file locations:

- [Service Reactor POM](pom.xml)
- [Service POM](bip-origin/pom.xml). Review `<bip-framework.version>` property value
- [Integration Test POM](bip-origin-inttest/pom.xml). Review `<bip-framework.version>` property value


# How to build and test?

The fastest way to get set up is to visit the [Quick Start Guide](https://github.ec.va.gov/EPMO/bip-reference-person/blob/master/docs/quick-start-guide.md).

# Local Development

Instructions on running the application on a local workstation can be found in the [local-dev README](local-dev)

# Contribution guidelines

If you or your team wants to contribute to this repository, then fork the repository and follow the steps to create a PR for our upstream repo to review and commit the changes: [Creating a pull request from a fork](https://help.github.com/articles/creating-a-pull-request-from-a-fork/)

