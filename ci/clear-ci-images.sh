#!/usr/bin/env bash
# Remove all images created in a CI run
docker image rm --force ci_db:latest ci_s1:latest ci_s2:latest ci_test:latest
