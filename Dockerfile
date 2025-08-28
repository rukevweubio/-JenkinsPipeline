# Multi-stage build
FROM gradle:8.5-jdk17 AS build

# Set working directory
WORKDIR /app

# Copy Gradle files
COPY build.gradle settings.gradle ./
COPY gradle gradle

# Copy source code
COPY src src

# Build the application
RUN gradle bootJar --no-daemon

# Runtime stage
FROM openjdk:17-jre-slim

# Set working directory
WORKDIR /app

# Copy JAR from build stage
COPY --from=build /app/build/libs/app.jar app.jar

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/api/health || exit 1

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]