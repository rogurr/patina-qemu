#!/usr/bin/env bash
# Start or create the patina-dev container for the Patina/QEMU dev environment
#

set -euo pipefail

IMAGE="ghcr.io/microsoft/mu_devops/ubuntu-24-dev:latest"
WORKSPACE="$PWD"

container_exists() {
  docker ps -a --format '{{.Names}}' | grep -Fxq "patina-dev"
}

container_running() {
  docker ps --format '{{.Names}}' | grep -Fxq "patina-dev"
}

echo "➡️  Image:       $IMAGE"
echo "➡️  Workspace:   $WORKSPACE"
echo "➡️  Container:   patina-dev"

if container_exists; then
  if container_running; then
    echo "✅ Container 'patina-dev' is already running, attaching shell"
    exec docker exec -it "patina-dev" /bin/bash
  else
    echo "✅ Starting existing container 'patina-dev'"
    exec docker start -ai "patina-dev"
  fi
else
  echo "✅ Creating new container 'patina-dev'"
  docker run -it --privileged --name "patina-dev" -v "$WORKSPACE:/workspace" -p 5005-5008:5005-5008 -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY="${DISPLAY:-:0}" "$IMAGE" /bin/bash
fi
