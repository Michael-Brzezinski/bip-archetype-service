FROM java:8

# Add a volume pointing to /tmp
VOLUME /tmp

# The application's jar file
ARG JAR_FILE=target/bip-origin.jar

# Add the application's jar to the container
ADD ${JAR_FILE} bip-origin.jar

# Run the jar file 
ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom","-jar","/bip-origin.jar"]

ADD ./scripts/wait-for-it.sh /wait-for-it.sh
