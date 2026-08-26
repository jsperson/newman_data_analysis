#!/bin/bash
# Jupyter docker environment for DSCI-6883 Descriptive Analysis & Data Integrity.
# - launches Docker Desktop if the daemon is down
# - downloads the image if not available locally
# - creates the container if it doesn't exist
# - starts the container if it's stopped
# - prints the Jupyter URL and drops you at a shell INSIDE the container
#
# Mount: <script_dir>/docker_mount  <->  /home/jsperson  (in container)
# Jupyter root dir in container:   /home/jsperson/work
set -euo pipefail

cd "$(dirname "$0")"

IMAGE="quay.io/jupyter/datascience-notebook:latest"
NAME="dsci-jupyter"
HOST_MOUNT="$(pwd)/docker_mount"
CONTAINER_HOME="/home/jsperson"
CONTAINER_WORK="$CONTAINER_HOME/work"
PORT=8888

# Docker Desktop ships its CLI outside the default PATH on some setups.
export PATH="/usr/local/bin:/Applications/Docker.app/Contents/Resources/bin:$PATH"

step() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

mkdir -p "$HOST_MOUNT/work"

# --- 1. Make sure the Docker daemon is up -----------------------------------
if ! docker info >/dev/null 2>&1; then
  step "Docker daemon not up; launching Docker Desktop..."
  open -a Docker
  for _ in $(seq 1 60); do
    docker info >/dev/null 2>&1 && break
    sleep 2
  done
  docker info >/dev/null 2>&1 || { echo "ERROR: Docker daemon did not come up." >&2; exit 1; }
fi

# --- 2. Make sure the image exists locally ----------------------------------
if [ -z "$(docker images -q "$IMAGE" 2>/dev/null)" ]; then
  step "Image $IMAGE not found locally; pulling (this can take a few minutes)..."
  docker pull "$IMAGE"
fi

# --- 3. Create the container if missing -------------------------------------
if ! docker ps -a --format '{{.Names}}' | grep -qx "$NAME"; then
  step "Creating container $NAME..."
  docker create \
    --name "$NAME" \
    -p "0.0.0.0:$PORT:8888" \
    -v "$HOST_MOUNT:$CONTAINER_HOME" \
    -e JUPYTER_ENABLE_LAB=yes \
    -e CHOWN_HOME=yes \
    -e CHOWN_HOME_OPTS='-R' \
    --user root \
    "$IMAGE" \
    start-notebook.py \
      --ServerApp.root_dir="$CONTAINER_WORK" \
      --ServerApp.token='' \
      --ServerApp.password='' \
      --ServerApp.disable_check_xsrf=True >/dev/null
fi

# --- 4. Start it if it's not running ----------------------------------------
if ! docker ps --format '{{.Names}}' | grep -qx "$NAME"; then
  step "Starting container $NAME..."
  docker start "$NAME" >/dev/null
fi

# --- 5. Report status + URL --------------------------------------------------
for _ in $(seq 1 30); do
  TOKEN=$(docker logs "$NAME" 2>&1 | grep -oE 'token=[a-f0-9]+' | tail -1 | cut -d= -f2)
  [ -n "$TOKEN" ] && break
  sleep 1
done

step "Container: $NAME ($(docker inspect -f '{{.State.Status}}' "$NAME"))"
step "Mount:     $HOST_MOUNT  <->  $CONTAINER_HOME"
step "Jupyter:   http://localhost:$PORT/lab"
step "Tailscale: http://$( { command -v tailscale >/dev/null && tailscale ip -4; } || /Applications/Tailscale.app/Contents/MacOS/Tailscale ip -4 ) 2>/dev/null):$PORT/lab"
step "  (no token required — reachable from anywhere on your tailnet)"
step "Dropping you at a shell inside the container (exit to leave)..."
docker exec -it -u jovyan -w "$CONTAINER_WORK" "$NAME" /bin/bash
