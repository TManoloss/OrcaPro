# Stage 1: Build
FROM maven:3.9.6-eclipse-temurin-17-alpine AS build
WORKDIR /app
COPY . .
RUN mvn clean package -DskipTests

# Stage 2: Run
FROM eclipse-temurin:17-alpine
WORKDIR /app

# Instala dependências para o script de espera
RUN apk add --no-cache netcat-openbsd

COPY --from=build /app/target/*.jar app.jar
COPY wait-for-postgres.sh /wait-for-postgres.sh
RUN chmod +x /wait-for-postgres.sh

EXPOSE 8080
ENTRYPOINT ["/wait-for-postgres.sh", "postgres", "5432", "java", "-jar", "app.jar"]