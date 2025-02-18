#!/bin/bash
if [ -z "$1" ]; then
    echo "Usage: $0 <version>"
    exit 1
fi
docker buildx build -t immauss/tak-tak:$1 -f Dockerfile.tak . --load
docker buildx build -t immauss/tak-db:$1 -f Dockerfile.db . --load