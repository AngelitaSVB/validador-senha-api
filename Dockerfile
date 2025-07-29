
FROM eclipse-temurin:17-jdk-alpine

WORKDIR /app

COPY target/validador-senha-api-*.jar app.jar

ENV JAVA_OPTS=""

ENTRYPOINT exec java $JAVA_OPTS -jar app.jar
