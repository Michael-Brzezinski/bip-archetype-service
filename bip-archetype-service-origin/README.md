# BIP Service Archetype Origin Project

This project is the origin (or "source") project from which a new BIP Service project can be created.

This Origin project should never be deployed to any server. It is a tool to ease the creation of a new service project.

This project is dependent on the libraries from **BIP framework a.k.a Blue** for auto configuration, common shared libraries, parent pom maven configuration and functional testing library. These framework artifacts are included in the pom.xml files of the origin project modules.

For the most current version of BIP Framework configured in the project, reviewed the following files:

- [Service Reactor POM](pom.xml)
- [Service POM](bip-origin/pom.xml). Review `<bip-framework.version>` property value
- [Integration Test POM](bip-origin-inttest/pom.xml). Review `<bip-framework.version>` property value

## What is in (and not in) this project?

Some capabilities that are provided in [bip-reference-person](https://github.ec.va.gov/EPMO/bip-reference-person) for instructional purposes are omitted from the Origin project. Also, beyond the necessary, this project does not attempt to anticipate the needs of projects that will be built on the BIP Platform. It provides the base code and configuration for core functionality, and provides starting points for unit tests, integration tests, and performance tests.

Included capabilities:

- Files for Jenkins, Helm, docker config of vault, consul, etc.
- Core code for basic application configuration, spring Application class, REST API provider, service impl, model transformation, validation, logging, file uploads and downloads, database reads and writes (including auditing), and exception handling.
- Branches in source control are used to provide optional components (e.g database configuration, SOAP partner integration).

Omitted capabilities:

- SOAP Partner Clients. For reasons of code reuse and consistent implementation, it is suggested that partner client code should reside in separate repositories to allow for consumption by other BIP projects. At a time when sufficient need becomes evident, partner client Origin project(s) may be created.

  - The Feign Client code (REST client) and config have been removed.
  - The `bip-reference-partner-person` SOAP service project has been removed. It is worth noting that the service Helper class remains in the project as a template for SOAP client calls.

# Creating a New Project from Origin

See the [root README](../README.md).

# Updating the Origin Project

The Origin project is

## Understanding Components and the Master Branches

To provide optional capabilities when creating a project, the git repo contains branches that represent a component that could be added to a project. The component branch includes the necessary configuration, code, and documentation for that capability. At the time of this writing, there are three branches:

- `master` contains the core project skeleton configuration and code

- `master-db` is a child of `master` that contains

 	- everything from `master`

	- the configuration, code, and documentation for projects that require relational database access

- `master-partner` is a child of `master` that contains

	- everything from `master`

	- the configuration, code, and documentation for projects that will use SOAP partner client JAR(s)

The addition of new components will require

- A new "master-[option]" branch created from `master`

- Necessary component changes in the new branch - remember that any changes to the generic core code should be done in `master` and merged up

- Review of the `gen.sh` script to add any necessary capabilities to accommodate the new module

Some good maintenance rules of thumb:

- Changes to the generic core code should be made in the `master` branch, and merged up to the child branches.

- Changes to branch-specific code should never be "merged down" to master.

- Due to the nature of the script, testing can only be performed on the `master*` branches. As a result, it is recommended that maintenance updates to the archetype be scheduled around times in which new teams and projects are being on-boarded.

## Before starting modifications

Be aware that:

- The `gen.sh` script - in the newly created project directory - copies `archive/bip-archetype-service-newprojects-README.md` over top of this very README. If you need to make changes to that file, **change the README in the `bip-archetype-service-origin/archive` folder** so it can be included in future projects. You may need to manually copy it other existing new project(s).

The Origin project should only need to be updated when something new or different needs to be reflected in the typical new BIP Service projects, for example, when

- service development coding patterns have changed
- configuration patterns have changed
- dependency technologies have changed (e.g. during upgrades of spring-boot, hystrix, etc)
- enhancements or new capabilities have been added to BIP services that should be part of the standard service project offering

## Making Changes to the Origin Project Branches

1. Ensure that the `bip-archetype-service-origin` project builds, that the project can be run as a spring-boot app, and that the [localhost swagger page](http://localhost:8080/swagger-ui.html) opens and responds as expected.

2. Make the desired changes in the appropriate `master*` branch.

3. Remember that the new project README is in the `bip-archetype-service-origin/archive` folder, so make any necessary changes to that file.

4. Use the `./gen.sh` script to generate the MyTest project (using the default `gen.properties`), testing the generated project as you would with any spring-boot application.
