#!/bin/sh
#
# Runs the web app locally.

source docker/env.sh

docker run -p 3000:3000 -it --env-file docker/env.list $APP_NAME
