#!/usr/bin/env bash
# Build the Docker bridge image from only the sources the standalone host needs.
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "$0")/../../.." && pwd)"
IMAGE="${PJARCZAK_DOCKER_IMAGE:-pjarczak-bambu-linux-host:02.08.02.54}"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
mkdir -p "$STAGE/src"
cd "$ROOT"
for path in tools/pjarczak_bambu_linux_host shared src/slic3r/Utils/PJarczakLinuxBridge src/slic3r/Utils/bambu_networking.hpp \
            src/slic3r/GUI/Printer/BambuTunnel.h deps_src/nlohmann; do
  rsync -a --relative --exclude '.build*' --exclude 'runtime/' "$path" "$STAGE/src/"
done
cp "$ROOT/tools/pjarczak_bambu_linux_host/docker/Dockerfile" "$STAGE/Dockerfile"
# x86-64 hosts run the Linux image directly; Apple silicon gets the QEMU-wrapped image (see the Dockerfile).
if [[ "$(uname -m)" == "x86_64" ]]; then target=x86; else target=qemu; fi
docker build --target "$target" -t "$IMAGE" "$STAGE"
echo "built $IMAGE"
