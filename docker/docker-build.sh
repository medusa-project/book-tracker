#!/bin/sh

source docker/env.sh

docker build -f docker/Dockerfile \
    --build-arg time_zone=$TIME_ZONE \
    -t $APP_NAME \
    .
