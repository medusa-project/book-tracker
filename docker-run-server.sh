#!/bin/sh

source ./env.sh

docker run \
    -p 3000:3000 \
    --env-file env.list \
    $APP_NAME
