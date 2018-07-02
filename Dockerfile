# STAGE: Build
FROM openjdk:8-alpine as builder

# Create Working Directory
ENV BUILD_DIR=/
RUN mkdir $BUILD_DIR
WORKDIR $BUILD_DIR

# Set permissions
USER root
RUN chown -R gradle $BUILD_DIR
USER gradle

# Download Dependencies
COPY build.gradle gradlew gradlew.bat $BUILD_DIR
COPY gradle $BUILD_DIR/gradle
RUN ./gradlew build -x :bootRepackage -x test --continue

# Copy Code Over and Build jar
COPY . .
RUN ./gradlew build -x test

# STAGE: Deploy
FROM openjdk:8-jre-alpine

# Install Extra Packages
RUN apk --no-cache update \
 && apk add jq bash bc

# Create app directory
ENV APP_HOME=/
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

# Copy jar file over from builder stage
COPY --from=builder /build/libs/micro-catalog-0.0.1.jar $APP_HOME
RUN mv ./micro-catalog-0.0.1.jar app.jar

COPY startup.sh startup.sh
COPY scripts scripts

EXPOSE 8081
ENTRYPOINT ["./startup.sh"]