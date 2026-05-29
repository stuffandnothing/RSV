#!/bin/bash
# dev.sh — build and launch the rsv dev container

set -e

IMAGE="rsv-dev"
RSV_REPO="$(cd "$(dirname "$0")" && pwd)"
RSV_MAIN="$(cd "$RSV_REPO/.." && pwd)"

# Build if image doesn't exist or --build is passed
if [[ "$1" == "--build" ]] || ! docker image inspect "$IMAGE" &>/dev/null; then
    echo "Building $IMAGE..."
    docker build -t "$IMAGE" "$(dirname "$0")/docker"
fi

echo "Launching rsv dev container..."
echo "Repo: $RSV_REPO -> /rsv"
echo "Shim: $RSV_MAIN/rsv-ng-systemctl -> /rsv-ng-systemctl"
echo ""

docker run --rm -it \
    --name rsv-dev \
    --privileged \
    -v "$RSV_REPO:/rsv" \
    -v "$RSV_MAIN/rsv-ng-systemctl:/rsv-ng-systemctl" \
    "$IMAGE" \
    bash
