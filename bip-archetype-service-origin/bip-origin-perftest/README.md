##What is this project for?
This document provides details for **Origin Service Performance Testing**.

## Performance tests for Origin Service
Performance tests are executed to guage if the application would be able to handle a reasonable request load.

The project uses Apache JMeter.

It is recommended that JMeter GUI mode be used for developing tests, and command mode (command-line execution) for test execution.

## Project Structure

`pom.xml` - The Maven configuration for building and deploying the project.

`src/test/jmeter` - Performance testing configurations (jmx files) go in this directory.

## Execution

Testing executes requests against the rest end points available in Origin Service.

Every request must contain a valid JWT header, so every test calls the `/token` end point to generate a JWT token for the user.

## Performance Test Configuration

The test suite can be configured to:
- execute each test a different number of times
- execute each test with different number of threads.

Below is an example of typical configuration values. To override any of the properties, pass them on the command line as `-D` arguments, e.g. `-Ddomain=(env)`.

|Property|Description|Default Value|Perf Env Test Values|
|-|-|-|-|
|domain| Origin service Base Url|localhost| |
|port|Origin Service Port|8080|443 |
|protocol|Origin Service Protocol|http|https |
|Health.threadGroup.threads|Number of threads for Health Status|5|150|
|Health.threadGroup.rampUp|Thead ramp up|2|150|
|Health.threadGroup.loopCount|Number of executions|10|-1|
|Health.threadGroup.duration|Scheduler Duration in seconds|200|230|
|Health.threadGroup.startUpDelay|Delay to Start|5|30|
|SampleInfo.threadGroup.threads|Number of threads for PID based Sample Info|5|150|
|SampleInfo.threadGroup.rampUp|Thead ramp up|2|150|
|SampleInfo.threadGroup.loopCount|Number of executions|10|-1|
|SampleInfo.threadGroup.duration|Scheduler Duration in seconds|200|230|
|SampleInfo.threadGroup.startUpDelay|Delay to Start|2|30|
|SampleInfoNoRecordFound.threadGroup.threads|Number of threads PID based Sample Info with No Record Found PID|5|150|
|SampleInfoNoRecordFound.threadGroup.rampUp|Thead ramp up|2|150|
|SampleInfoNoRecordFound.threadGroup.loopCount|Number of executions |10|-1|
|SampleInfoNoRecordFound.threadGroup.duration|Scheduler Duration in seconds|200|230|
|SampleInfoNoRecordFound.threadGroup.startUpDelay|Delay to Start|2|30|
|SampleInfoInvalidPid.threadGroup.threads|Number of threads PID based Sample Info with Invalid PID|5|150|
|SampleInfoInvalidPid.threadGroup.rampUp|Thead ramp up|2|150|
|SampleInfoInvalidPid.threadGroup.loopCount|Number of executions |10|-1|
|SampleInfoInvalidPid.threadGroup.duration|Scheduler Duration in seconds|200|230|
|SampleInfoInvalidPid.threadGroup.startUpDelay|Delay to Start|2|30|
|SampleInfoNullPid.threadGroup.threads|Number of threads PID based Sample Info with null PID|5|150|
|SampleInfoNullPid.threadGroup.rampUp|Thead ramp up|2|150|
|SampleInfoNullPid.threadGroup.loopCount|Number of executions |10|-1|
|SampleInfoNullPid.threadGroup.duration|Scheduler Duration in seconds|200|230|
|SampleInfoNullPid.threadGroup.startUpDelay|Delay to Start|2|30|
|BearerTokenCreate.threadGroup.threads|Number of threads for Bearer Token Create/Generate|5|150|
|BearerTokenCreate.threadGroup.rampUp|Thead ramp up|1|50|
|BearerTokenCreate.threadGroup.loopCount|Number of executions |1|1|

## Running the tests

To execute performance tests locally, navigate to the `bip-origin-perftest` directory, and run
```bash
	mvn clean verify -Pperftest
```
If you need to override any of the properties add the to the command using the appropriate `-Dpropety=value` argument(s).

#### Sample Command
An example for executing the test in performance test environment:

```bash
     mvn clean verify -Pperftest -Dprotocol=<> -Ddomain=<> -Dport=<> -DBearerTokenCreate.threadGroup.threads=150
      -DBearerTokenCreate.threadGroup.rampUp=50 -DBearerTokenCreate.threadGroup.loopCount=1 -DHealth.threadGroup.threads=150 -DHealth.threadGroup.rampUp=150 -DHealth.threadGroup.loopCount=-1 -DHealth.threadGroup.duration=230 -DHealth.threadGroup.startUpDelay=30 -DSampleInfo.threadGroup.threads=150 -DSampleInfo.threadGroup.rampUp=150 -DSampleInfo.threadGroup.loopCount=-1 -DSampleInfo.threadGroup.duration=230 -DSampleInfo.threadGroup.startUpDelay=30 -DSampleInfoNoRecordFound.threadGroup.threads=150 -DSampleInfoNoRecordFound.threadGroup.rampUp=150 -DSampleInfoNoRecordFound.threadGroup.loopCount=-1 -DSampleInfoNoRecordFound.threadGroup.duration=230 -DSampleInfoNoRecordFound.threadGroup.startUpDelay=30 -DSampleInfoInvalidPid.threadGroup.threads=150 -DSampleInfoInvalidPid.threadGroup.rampUp=150 -DSampleInfoInvalidPid.threadGroup.loopCount=-1 -DSampleInfoInvalidPid.threadGroup.duration=230 -DSampleInfoInvalidPid.threadGroup.startUpDelay=30 -DSampleInfoNullPid.threadGroup.threads=150 -DSampleInfoNullPid.threadGroup.rampUp=150 -DSampleInfoNullPid.threadGroup.loopCount=-1 -DSampleInfoNullPid.threadGroup.duration=230 -DSampleInfoNullPid.threadGroup.startUpDelay=30
```

## How to set up JMeter and Create Test Plan (JMX)
For an example from the BIP Reference app, see [BIP Reference - Performance Testing Guide](https://github.ec.va.gov/EPMO/bip-reference-person/tree/master/bip-reference-perftest)
