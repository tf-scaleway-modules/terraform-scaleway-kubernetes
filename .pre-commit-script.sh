#!/bin/bash

current_branch=$(git rev-parse --abbrev-ref HEAD)

if [ "$current_branch" == "develop" ]; then
    sed -i 's|gitlab.com:leminnov|gitlab.com:${GITLAB_GROUP_PATH}|g' main.tf
    sed -i 's|gitlab.com:d3_vw/cloud|gitlab.com:${GITLAB_GROUP_PATH}|g' main.tf

elif [ "$current_branch" == "main-leminnov" ]; then
    sed -i 's|gitlab.com:${GITLAB_GROUP_PATH}|gitlab.com:leminnov|g' main.tf
    sed -i 's|gitlab.com:d3_vw/cloud|gitlab.com:leminnov|g' main.tf

elif [ "$current_branch" == "main-d3" ]; then
    sed -i 's|gitlab.com:${GITLAB_GROUP_PATH}|gitlab.com:d3_vw/cloud|g' main.tf
    sed -i 's|gitlab.com:leminnov|gitlab.com:d3_vw/cloud|g' main.tf
else
    echo 'Not matching any branch. Did you forget to configure this script for the current branch?' 1>&2
    exit 0
fi
