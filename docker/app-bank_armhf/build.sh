#!/bin/bash

APP="app-bank_armhf"
APP_GIT="app-bank"
APP_NAME="kontoentwicklung"

# read commandline options
REFRESH=false
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
        --refresh*)
            REFRESH=true
            ;;
        --run*)
            RUN_LOCAL=true
            ;;
        *)
            printf "unbekannte Option(en)\n"
            if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
                return 1
            else
                exit 1
            fi
    esac
    shift
done

if $REFRESH; then
    if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
        cd ~/docker
        rm -rf $APP
        svn checkout https://github.com/OwnYourData/$APP_GIT/trunk/docker/$APP
        echo "refreshed"
        cd ~/docker/$APP
        return
    else
        echo "you need to source the script for refresh"
        exit
    fi
fi

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
