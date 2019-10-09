## What is this project for?
This document provides the details of **Origin Service Functional Testing**.

## Functional tests for Origin Service
Functional test are created to make sure the end points in origin are working as expected.

Project is built on Java and Maven, and uses the Sring RestTemplate jars for core API validations.

## Project Structure

`pom.xml` - The Maven configuration for building and deploying the project.

`src/inttest/resources/gov/va/origin/feature` - This is where you will create the cucumber feature files that contain the Feature
and Scenarios for the Origin service you are testing. As a good practice, it is suggested to group all the similar business functionality in one feature file.

`src/inttest/java/gov/va/bip/origin/service/steps` - The implementation steps related to the feature and scenarios mentioned in the cucumber file for the API needs to be created in this location.  In GenericSteps.java class Generic steps like validating the status code, setting header for the service are implemented here to avoid duplication of steps implementation.

`src/inttest/java/gov/va/bip/origin/service/runner` - Cucumber runner class that contains all feature file entries that needs to be executed at runtime. The annotations provided in the cucumber runner class will assist in bridging the features to step definitions.

`src/inttest/resources/request/dev` – This folder contains DEV request files if the body of your API call is static and needs to be sent as a XML/JSON file.

`src/inttest/resources/request/va` – This folder contains VA request files if the body of your API call is static and needs to be sent as a XML/JSON file.

`src/inttest/resources/response` – This folder contains response files that you may need to compare output, you can store the Response files in this folder. 

`src/test/resources/users/dev` - All the property files for DEV users should go under this folder.

`src/test/resources/users/va` - All the property files for VA users should go under this folder.

`src/inttest/resources/logback-test.xml` - Logback Console Appender pattern and loggers defined for this project.
Various packages and their corresponding log levels are specified here. By Default, the log level is WARN and it can be overridden by runtime environment variable. For e.g., -DLOG_LEVEL_BIP_FRAMEWORK_TEST=INFO

`src/inttest/resources/config/origin-inttest-dev.properties` – DEV configuration properties such as URL are specified here.

`src/inttest/resources/config/origin-inttest-stage.properties` – STAGE configuration properties such as URL are specified here.

**Note: All the configurations are defined external to the code and is per profile/environment. The naming convention of the file is vetservices-inttest-&lt;env>.properties**

## Execution

To execute the functional tests in local bip-origin the service needs to be up and running.

# How to Build and Test origin service
[Quick Start Guide](/docs/quick-start-guide.md)

**Command Line:** Execute the Origin service functional tests using the environment specific command below. 
```bash
Default Local: mvn verify -Pinttest -Dcucumber.options="--tags @DEV" 
```

```bash
DEV: mvn verify -Pinttest -Dtest.env=dev -Ddockerfile.skip=true -Dcucumber.options="--tags @DEV"
```


## More Details For Functional Test
For examples from the BIP Reference service, see [Integration Testing Guide](https://github.ec.va.gov/EPMO/bip-reference-person/tree/master/bip-reference-inttest)

