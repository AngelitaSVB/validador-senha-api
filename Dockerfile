FROM eclipse-temurin:17-jdk-alpine

WORKDIR /app

# Copia o JAR gerado com Spring Boot
COPY target/validador-senha-api-*.jar app.jar

# Permite passar flags Java opcionais no build/run
ENV JAVA_OPTS=""

# Usa shell-form para evitar erros com variável ENV
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar app.jar"]
