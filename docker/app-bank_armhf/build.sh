#!/bin/bash

APP="app-bank_armhf"
APP_NAME="kontoentwicklung"

# read commandline options
BUILD_CLEAN=false
DOCKER_UPDATE=false
RUN_LOCAL=false
while [ $# -gt 0 ]; do
    case "$1" in
        --clean*)
            BUILD_CLEAN=true
            ;;
        --dockerhub*)
            DOCKER_UPDATE=true
            ;;
        --run*)
            RUN_LOCAL=true
            ;;
        *)
            printf "unbekannte Option(en)\n"
            exit 1
    esac
    shift
done

if $BUILD_CLEAN; then
    docker build --no-cache -t oydeu/$APP .
else
    docker build -t oydeu/$APP .
fi

if $DOCKER_UPDATE; then
    docker push oydeu/$APP
fi

if $RUN_LOCAL; then
    docker stop $APP_NAME
    docker rm $(docker ps -q -f status=exited)
    docker run --name $APP_NAME oydeu/$APP
fi
