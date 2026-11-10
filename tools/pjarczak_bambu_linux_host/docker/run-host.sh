#!/usr/bin/env bash
# Bridge command for the MCP: run the Linux host in Docker. The host's stdin/stdout carry the framed RPC, so nothing
# else may write to stdout. The MCP's config folder and temp folder (where it snapshots print files) are mounted at
# the same absolute paths, because the MCP passes file paths through unchanged.
set -euo pipefail
IMAGE="${PJARCZAK_DOCKER_IMAGE:-pjarczak-bambu-linux-host:02.08.02.54}"
CONFIG_ROOT="${PJARCZAK_DOCKER_CONFIG_ROOT:-$HOME/.config/bambu-printer-mcp}"
TMP="${TMPDIR:-${TMP:-${TEMP:-/tmp}}}"
TMP="${TMP%/}"
mounts=(-v "$CONFIG_ROOT:$CONFIG_ROOT" -v "$TMP:$TMP")
real_tmp="$(cd "$TMP" && pwd -P)"
[[ "$real_tmp" != "$TMP" ]] && mounts+=(-v "$real_tmp:$real_tmp")
exec docker run -i --rm --init --log-driver none "${mounts[@]}" "$IMAGE" "$@"
