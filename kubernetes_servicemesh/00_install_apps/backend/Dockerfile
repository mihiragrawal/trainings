FROM gradle:8.6.0-jdk21 AS builder
ARG BUILD_VERSION=0.0.0
COPY --chown=gradle:gradle . /code
WORKDIR /code
RUN gradle build --no-daemon -Pversion=$BUILD_VERSION

FROM openjdk:21-jdk-slim-bookworm
RUN apt update && apt install curl -y
ARG BUILD_VERSION=0.0.0
ENV BUILD_VERSION=$BUILD_VERSION
COPY --from=builder /code/build/libs/backend-$BUILD_VERSION.jar /srv/app/backend-$BUILD_VERSION.jar
WORKDIR /srv/app

ENTRYPOINT java -server -XshowSettings:vm -XX:InitialRAMPercentage=50 -XX:MaxRAMPercentage=70 -jar /srv/app/backend-$BUILD_VERSION.jar
