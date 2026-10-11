#!/data/data/com.termux/files/usr/bin/sh
# ==============================================================================
# scripts/termux_boot.sh
# Termux:Boot script for MJ Tactical OS Sovereign Edge Gateway
# Copy this file to ~/.termux/boot/ to start the gateway automatically on boot.
# ==============================================================================

PROJECT_DIR="/data/data/com.termux/files/home/mj-tactical-os"
LOG_FILE="${PROJECT_DIR}/logs/boot-gateway.log"

mkdir -p "${PROJECT_DIR}/logs"

if [ -d "${PROJECT_DIR}" ]; then
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] Starting MJ Tactical OS Gateway via Termux:Boot..." >> "${LOG_FILE}"
    cd "${PROJECT_DIR}"
    termux-wake-lock 2>/dev/null || true
    node device-gateway.js >> "${LOG_FILE}" 2>&1 &
fi
