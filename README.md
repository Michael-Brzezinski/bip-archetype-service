Note : Please read all the instructions for maintaining and updating this project outlined at the end of this document before making any changes to the project or any of its branches starting with 'master-'.  

# BIP Service Archetype Project

This project **_is not_** a "maven archetype" because the `archetype:create-from-project` and `archetype:generate` mojos were not built for the task undertaken here, and they introduce a great deal of unnecessary complexity with unresolvable circular processes.

This project **_is_** an archetypal process from which an "origin" (or "source") project can be used to create the skeleton for a new BIP Service project.

This repository is comprised of:

- An origin (or source) project from which new BIP Service projects can be created.
- A script and properties that can be used to create the new BIP Service project. Optionally include configuration and skeleton code for
 	- relational databases, including preconfigured dtasources for multiple databases
	- client calls to SOAP partner JARs

The newly created artifact will contain a skeleton project with some rudimentary sample data objects demonstrating a simple use case.

To prepare and publish a new project for development, Tech Leads have only a few straight forward tasks, as outlined below.

## Getting the BIP Archetype Service project

The root project directory hosts the `bip-archetype-service-origin` project. This project contains the Origin service app (that is, the "source" project) from which new BIP Service projects can be created.

1. Clone the project:

  - `$ cd ~/git`
  - `$ git clone https://github.ec.va.gov/EPMO/bip-archetype-service`

2. Import into an appropriate IDE workspace.

  - It is not necessary to add the root directory (where the `gen.sh` script is) to your IDE. If you wish to do so, you will likely require a separate workspace just for that project.

  - To add the `bip-archetype-service-origin` project, import it to your IDE workspace as you would any other existing maven project.

## About The Origin Project

The `bip-archetype-service-origin` project contains the origin (or "source") project from which the new project can be created. This project is based on the [bip-reference -person](https://github.ec.va.gov/EPMO/bip-reference-person) project, with some sample features removed, and necessary naming genericized.

This project need only be modified when there are new features or capabilities to be included in a new generation of BIP Service projects.

See the [bip-archetype-service-origin README.md](./bip-archetype-service-origin/README.md) for details on modifying the Origin project.

The origin project is dependent on the libraries from **BIP framework a.k.a Blue** for auto configuration, common shared libraries, parent pom maven configuration and functional testing library. These framework artifacts are included in the pom.xml files of the origin project modules.

For the most current version of BIP Framework configured in the project, reviewed the following files:

- [Service Reactor POM](bip-archetype-service-origin/pom.xml)
- [Service POM](bip-archetype-service-origin/bip-origin/pom.xml). Review `<bip-framework.version>` property value
- [Integration Test POM](bip-archetype-service-origin/bip-origin-inttest/pom.xml). Review `<bip-framework.version>` property value


## Generating a New Project

> To generate a new project, your local environment must have access to `bip-framework`. Provide one of:
> 1. Access to BIP Nexus Repository at the URL specified in [`bip-archetype-service-origin/pom.xml`](bip-archetype-service-origin/pom.xml)
> 2. Local artifact in `~/.m2/repository` by cloning [`bip-framework`](https://github.ec.va.gov/EPMO/bip-framework), and building with `mvn clean install -U`

The `gen.sh` script and `gen.properties` file are central to generating a new project skeleton. Review the comments in the `gen.properties` file for information about how the results of script execution can be altered, and how to add (or not) the optional components.

Help for the script can be displayed by executing `./gen.sh -h`

<details><summary>Script Help Output</summary>

```asciidoc
=========================================================================
Generate a BIP Service project
=========================================================================

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
+>> Processing command-line arguments

./gen.sh : Generate a new skeleton project from the origin project.
  To generate your new project skeleton:
  1. Update gen.properties with values for your new project.
  2. Run ./gen.sh (with relevant options) to create the new project.
  3. Move the project folder to your git directory and git initialize it.
Examples:
  ./gen.sh -h  show this help
  ./gen.sh     generate project using gen.properties file
  ./gen.sh -s  skip (re)building the Origin source project
  ./gen.sh -o  over-write new project if it already exists
  ./gen.sh -d  build docker image (docker must be running)
  ./gen.sh -so both skip build, and overwrite

Notes:
* Full instructions available in development branch at:
  https://github.ec.va.gov/EPMO/bip-archetype-service/
* A valid "gen.properties" file must exist in the same directory
  as this script.
* It is recommended that a git credential helper be utilized to
  eliminate authentication requests while executing. For more info see
  https://help.github.com/articles/caching-your-github-password-in-git/



 Help: "./gen.sh -h"
 Logs: "/Users/aburkholder/git/bip-archetype-service/gen.log"
       search: "+>> " (script); "sed: " (sed); "FAIL" (mvn & cmd)
------------------------------------------------------------------------
```

</details>

### Steps to generate a new skeleton project

1. Update `gen.properties`. Read the comments in the properties file for each property. Existing property values provide examples of how they should appear.
2. Generate the new project and read at least the last few lines of the script output. Example from the command line:

  ```bash
  $ cd ~/git/bip-archetype-service
  $ chmod +x gen.sh # optional if the script is not yet executable
  $ ./gen.sh
  ```

3. Move the project to the desired local git directory. For example:

  ```bash
  $ cd ~/git/bip-archetype-service
  $ mv [new-project-dir] ~/git/[new-project-dir]
  ```

4. Make any desired changes, for example remove the sample objects, add real data objects, add skeleton API, add skeleton service methods/classes, etc.

5. Make an initial commit to publish to a GitHub branch. For an example of how to do this, see [git_newrepo](https://gist.github.com/c0ldlimit/4089101) - the only difference is that you may want to commit into some branch other than _master_.

# Getting Started With Your New Service Application

The [reference application](https://github.ec.va.gov/EPMO/bip-reference-person) is a real functioning app  with concrete implementations of recommended code patterns. It provides examples for the fundamental capabilities that must exist in any BIP service application. Use this application as a guide for patterns and potential solutions.

# Instructions for the maintaining and updating the project

1. Branches starting with 'master-' should not be deleted.
2. The branches starting with 'master-' represent a specific component or piece of the project that can be optionally added or omitted. For example, master-db is a branch that contains the necessary code and other file changes to carry out db operations.
3. When any change is made to the master branch, the master branch needs to be merged with with all the branches starting with 'master-' and any resulting merge conflicts need to be resolved.  
4. When a new capability in the form of a component is added to this project, a branch called master-<name-of-new-component> will be created from the master branch.Then the changes related to adding the capability supplied by that component are added in this branch, without removing or modifying any lines inherited from master.
6. The new component name needs to be documented in the gen.properties file, before the 'components' property value, similar to how other components such as db and partner are documented.
