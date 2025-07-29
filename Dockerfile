FROM eclipse-temurin:17-jdk-alpine

WORKDIR /app

# Copia o JAR gerado com Spring Boot
COPY target/validador-senha-api-*.jar app.jar

# Permite passar flags Java opcionais no build/run
ENV JAVA_OPTS=""

# Expõe a porta 8080 para o ECS reconhecer
EXPOSE 8080

# Usa shell-form para permitir variáveis de ambiente
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar app.jar"]
