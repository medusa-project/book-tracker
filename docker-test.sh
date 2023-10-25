#!/bin/sh

docker compose rm -f book-tracker-test
docker compose -f docker-compose.yml -f docker-compose.test.yml up \
    --build --exit-code-from book-tracker-test

