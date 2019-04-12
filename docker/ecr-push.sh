#!/bin/sh
#
# Builds a Docker image and pushes it to AWS ECR.
#

source docker/env.sh

#./docker/docker-build.sh
eval $(aws ecr get-login --no-include-email --region $AWS_REGION --profile $AWS_PROFILE)
docker tag $DOCKER_TAG $ECR_HOST/$DOCKER_TAG
docker push $ECR_HOST/$DOCKER_TAG