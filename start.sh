#!/bin/sh
# ==============================================================================
# start.sh - MJ Tactical OS Launch Script
# Architecture: 5-Autonomous Agent Hierarchy
# ==============================================================================

set -eu

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
cd "${SCRIPT_DIR}"

echo "================================================================"
echo " 🐉 Launching MJ Tactical OS Sovereign Operations Gateway"
echo "================================================================"

# Check if node is available
if ! command -v node >/dev/null 2>&1; then
    echo "[ERROR] Node.js is required but not installed or not in PATH." >&2
    exit 1
fi

# Ensure dependencies are present
if [ ! -d "node_modules" ]; then
    echo "[*] Initializing dependencies..."
    npm install --omit=dev
fi

# Execute Gateway Daemon
exec node device-gateway.js "$@"
