#!/bin/sh
# Copies the opencode binary to the shared tools volume at /tools/opencode.
# Fork of https://github.com/kubeopencode/kubeopencode/blob/main/agents/opencode/entrypoint.sh

set -e

TOOLS_DIR="${TOOLS_DIR:-/tools}"
OPENCODE_BIN="${OPENCODE_BIN:-opencode}"
TARGET="${TOOLS_DIR}/${OPENCODE_BIN}"

echo "[opencode-init] Copying OpenCode binary to ${TARGET}..."
mkdir -p "${TOOLS_DIR}"
cp /opencode "${TARGET}"
chmod +x "${TARGET}"

echo "[opencode-init] OpenCode binary installed successfully (version $(cat /opencode-version 2>/dev/null || echo 'unknown'))."
echo "[opencode-init] Work containers can use: ${TARGET}"
