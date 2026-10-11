#!/usr/bin/env bash
# ==============================================================================
# scripts/audit_platform.sh
# Mj-work-ai Sovereign Platform Security & Health Audit Script
# Environment: Kali NetHunter / Linux Operations Node
# Function: Audits API responsiveness, vital ports, network latency, and Zero-Trust auth.
# Output: Structured JSON report persisted to reports/ and printed to stdout.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONFIG_FILE="${BASE_DIR}/config.json"
TOKEN_FILE="${BASE_DIR}/.gateway_token"
REPORT_DIR="${BASE_DIR}/reports"

mkdir -p "${REPORT_DIR}"

# Default parameters
HOST_ARG=""
PORT_ARG=""
TOKEN_ARG=""
OUTPUT_ARG=""
TIMEOUT_SEC=5
QUIET_MODE=0

# Parse CLI arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--host)
      HOST_ARG="$2"
      shift 2
      ;;
    -p|--port)
      PORT_ARG="$2"
      shift 2
      ;;
    -t|--token)
      TOKEN_ARG="$2"
      shift 2
      ;;
    -o|--output)
      OUTPUT_ARG="$2"
      shift 2
      ;;
    -q|--quiet)
      QUIET_MODE=1
      shift
      ;;
    --help)
      echo "Usage: $0 [OPTIONS]"
      echo "  -h, --host HOST       Target host (default: config.json or 127.0.0.1)"
      echo "  -p, --port PORT       Target port (default: config.json or 4848)"
      echo "  -t, --token TOKEN     Bearer auth token (default: auto-detected)"
      echo "  -o, --output FILE     Custom JSON report destination file"
      echo "  -q, --quiet           Quiet mode (suppress log output, print only JSON)"
      exit 0
      ;;
    *)
      shift
      ;;
  esac
done

log() {
  if [[ "${QUIET_MODE}" -eq 0 ]]; then
    echo "[*] $*" >&2
  fi
}

log_ok() {
  if [[ "${QUIET_MODE}" -eq 0 ]]; then
    echo "[+] $*" >&2
  fi
}

log_warn() {
  if [[ "${QUIET_MODE}" -eq 0 ]]; then
    echo "[-] $*" >&2
  fi
}

# 1. Resolve Host and Port
TARGET_HOST="${HOST_ARG}"
if [[ -z "${TARGET_HOST}" ]]; then
  if [[ -f "${CONFIG_FILE}" ]] && command -v jq &>/dev/null; then
    TARGET_HOST="$(jq -r '.server.host // "127.0.0.1"' "${CONFIG_FILE}" 2>/dev/null || echo "127.0.0.1")"
  else
    TARGET_HOST="127.0.0.1"
  fi
fi

TARGET_PORT="${PORT_ARG}"
if [[ -z "${TARGET_PORT}" ]]; then
  if [[ -f "${CONFIG_FILE}" ]] && command -v jq &>/dev/null; then
    TARGET_PORT="$(jq -r '.server.port // 4848' "${CONFIG_FILE}" 2>/dev/null || echo "4848")"
  else
    TARGET_PORT="4848"
  fi
fi

# 2. Resolve Auth Token
AUTH_TOKEN="${TOKEN_ARG}"
if [[ -z "${AUTH_TOKEN}" ]]; then
  if [[ -n "${GATEWAY_AUTH_KEY:-}" ]]; then
    AUTH_TOKEN="${GATEWAY_AUTH_KEY}"
  elif [[ -f "${CONFIG_FILE}" ]] && command -v jq &>/dev/null && [[ "$(jq -r '.server.security.authToken // empty' "${CONFIG_FILE}" 2>/dev/null)" != "" ]]; then
    AUTH_TOKEN="$(jq -r '.server.security.authToken' "${CONFIG_FILE}")"
  elif [[ -f "${TOKEN_FILE}" ]]; then
    AUTH_TOKEN="$(head -n 1 "${TOKEN_FILE}" | tr -d '\r\n[:space:]')"
  fi
fi

BASE_URL="http://${TARGET_HOST}:${TARGET_PORT}"
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
AUDIT_ID="audit-$(date +%s)-${RANDOM}"

log "Starting Mj-work-ai Platform Health & Security Audit on ${BASE_URL} (${TIMESTAMP})"

# Ensure jq or node is installed
if ! command -v jq &>/dev/null && ! command -v node &>/dev/null; then
  echo "Error: Either jq or node is required for JSON reporting." >&2
  exit 1
fi

# Initialize metrics
PORT_REACHABLE=false
PORT_LATENCY_MS=0
API_HEALTH_STATUS=0
API_HEALTH_LATENCY_MS=0
API_HEALTH_OK=false
API_HEALTH_BODY="{}"

SECURITY_REJECTION_OK=false
SECURITY_UNAUTH_CODE=0

DEVICE_STATUS_CODE=0
DEVICE_STATUS_LATENCY_MS=0
DEVICE_STATUS_OK=false
DEVICE_STATUS_BODY="{}"

DNS_LATENCY_MS=0
DNS_RESOLVED=false

OVERALL_STATUS="HEALTHY"

# 3. Port Reachability Check (using socat, bash /dev/tcp, or curl)
START_PORT_NS=$(date +%s%N 2>/dev/null || date +%s)
if command -v socat &>/dev/null; then
  if socat /dev/null "TCP4:${TARGET_HOST}:${TARGET_PORT},connect-timeout=${TIMEOUT_SEC}" 2>/dev/null; then
    PORT_REACHABLE=true
  fi
else
  if (exec 3<>/dev/tcp/"${TARGET_HOST}"/"${TARGET_PORT}") 2>/dev/null; then
    PORT_REACHABLE=true
    exec 3<&-
    exec 3>&-
  fi
fi
END_PORT_NS=$(date +%s%N 2>/dev/null || date +%s)

if [[ "${START_PORT_NS}" =~ ^[0-9]{19}$ ]] && [[ "${END_PORT_NS}" =~ ^[0-9]{19}$ ]]; then
  PORT_LATENCY_MS=$(awk "BEGIN {printf \"%.2f\", (${END_PORT_NS} - ${START_PORT_NS}) / 1000000}")
else
  PORT_LATENCY_MS=0
fi

if [[ "${PORT_REACHABLE}" == "true" ]]; then
  log_ok "TCP port ${TARGET_PORT} is reachable (${PORT_LATENCY_MS} ms)"
else
  log_warn "TCP port ${TARGET_PORT} is unreachable or closed"
  OVERALL_STATUS="CRITICAL"
fi

# 4. Zero-Trust Authentication Security Enforcement Test
# Testing endpoint without auth token must return HTTP 401
log "Auditing Zero-Trust access controls (unauthenticated probe)..."
UNAUTH_CURL=$(curl -s -S -m "${TIMEOUT_SEC}" -o /dev/null -w "%{http_code}" "${BASE_URL}/api/health" 2>/dev/null || echo "000")
SECURITY_UNAUTH_CODE="${UNAUTH_CURL}"
if [[ "${SECURITY_UNAUTH_CODE}" == "401" ]]; then
  SECURITY_REJECTION_OK=true
  log_ok "Zero-Trust enforcement verified: Unauthenticated request rejected with HTTP 401"
elif [[ "${SECURITY_UNAUTH_CODE}" == "000" ]]; then
  log_warn "Gateway server unreachable during unauthenticated probe"
else
  log_warn "SECURITY VULNERABILITY: Endpoint returned HTTP ${SECURITY_UNAUTH_CODE} without Bearer token!"
  OVERALL_STATUS="CRITICAL"
fi

# 5. Authenticated API Health Probe
if [[ -n "${AUTH_TOKEN}" ]]; then
  log "Probing authenticated /api/health endpoint..."
  CURL_TMP=$(mktemp)
  CURL_OUT=$(curl -s -S -m "${TIMEOUT_SEC}" \
    -H "Authorization: Bearer ${AUTH_TOKEN}" \
    -w "\n%{http_code}\n%{time_total}" \
    "${BASE_URL}/api/health" 2>/dev/null || echo -e "\n000\n0")

  TOTAL_TIME=$(echo "${CURL_OUT}" | tail -n 1)
  HTTP_CODE=$(echo "${CURL_OUT}" | tail -n 2 | head -n 1)
  BODY=$(echo "${CURL_OUT}" | sed '$d' | sed '$d')

  API_HEALTH_STATUS="${HTTP_CODE}"
  API_HEALTH_LATENCY_MS=$(awk "BEGIN {printf \"%.2f\", ${TOTAL_TIME} * 1000}" 2>/dev/null || echo "0")

  if [[ "${HTTP_CODE}" == "200" ]]; then
    API_HEALTH_OK=true
    API_HEALTH_BODY="${BODY}"
    log_ok "Health API returned 200 OK (Latency: ${API_HEALTH_LATENCY_MS} ms)"
  else
    log_warn "Health API returned HTTP ${HTTP_CODE}"
    if [[ "${OVERALL_STATUS}" != "CRITICAL" ]]; then
      OVERALL_STATUS="DEGRADED"
    fi
  fi
  rm -f "${CURL_TMP}"

  # 6. Authenticated Device Telemetry Probe
  log "Probing authenticated /api/device-status endpoint..."
  DEV_CURL_OUT=$(curl -s -S -m "${TIMEOUT_SEC}" \
    -H "Authorization: Bearer ${AUTH_TOKEN}" \
    -w "\n%{http_code}\n%{time_total}" \
    "${BASE_URL}/api/device-status" 2>/dev/null || echo -e "\n000\n0")

  DEV_TOTAL_TIME=$(echo "${DEV_CURL_OUT}" | tail -n 1)
  DEV_HTTP_CODE=$(echo "${DEV_CURL_OUT}" | tail -n 2 | head -n 1)
  DEV_BODY=$(echo "${DEV_CURL_OUT}" | sed '$d' | sed '$d')

  DEVICE_STATUS_CODE="${DEV_HTTP_CODE}"
  DEVICE_STATUS_LATENCY_MS=$(awk "BEGIN {printf \"%.2f\", ${DEV_TOTAL_TIME} * 1000}" 2>/dev/null || echo "0")

  if [[ "${DEV_HTTP_CODE}" == "200" ]]; then
    DEVICE_STATUS_OK=true
    DEVICE_STATUS_BODY="${DEV_BODY}"
    log_ok "Device status API returned 200 OK (Latency: ${DEVICE_STATUS_LATENCY_MS} ms)"
  else
    log_warn "Device status API returned HTTP ${DEV_HTTP_CODE}"
  fi
else
  log_warn "No Bearer Auth Token found. Skipping authenticated endpoint verification."
  if [[ "${OVERALL_STATUS}" != "CRITICAL" ]]; then
    OVERALL_STATUS="DEGRADED"
  fi
fi

# 7. DNS & Host Resolution Latency Check
DNS_START_NS=$(date +%s%N 2>/dev/null || date +%s)
if command -v dig &>/dev/null; then
  if dig +time=2 +tries=1 localhost @127.0.0.1 >/dev/null 2>&1 || dig +time=2 +tries=1 localhost >/dev/null 2>&1; then
    DNS_RESOLVED=true
  fi
else
  if getent hosts localhost >/dev/null 2>&1; then
    DNS_RESOLVED=true
  fi
fi
DNS_END_NS=$(date +%s%N 2>/dev/null || date +%s)
if [[ "${DNS_START_NS}" =~ ^[0-9]{19}$ ]] && [[ "${DNS_END_NS}" =~ ^[0-9]{19}$ ]]; then
  DNS_LATENCY_MS=$(awk "BEGIN {printf \"%.2f\", (${DNS_END_NS} - ${DNS_START_NS}) / 1000000}")
else
  DNS_LATENCY_MS=0
fi

# 8. Token File Security & Permission Check
TOKEN_FILE_EXISTS=false
TOKEN_FILE_PERMS=""
TOKEN_SECURE=false
if [[ -f "${TOKEN_FILE}" ]]; then
  TOKEN_FILE_EXISTS=true
  TOKEN_FILE_PERMS="$(stat -c "%a" "${TOKEN_FILE}" 2>/dev/null || stat -f "%Lp" "${TOKEN_FILE}" 2>/dev/null || echo "unknown")"
  if [[ "${TOKEN_FILE_PERMS}" == "600" || "${TOKEN_FILE_PERMS}" == "400" ]]; then
    TOKEN_SECURE=true
  fi
fi

# 9. Gather Host System Metrics
UPTIME_SEC="$(cut -d. -f1 /proc/uptime 2>/dev/null || echo "0")"
LOAD_AVG="$(cut -d' ' -f1-3 /proc/loadavg 2>/dev/null || echo "0 0 0")"
MEM_FREE_KB="$(grep MemAvailable /proc/meminfo 2>/dev/null | awk '{print $2}' || grep MemFree /proc/meminfo 2>/dev/null | awk '{print $2}' || echo "0")"
MEM_FREE_MB=$(awk "BEGIN {printf \"%.1f\", ${MEM_FREE_KB} / 1024}" 2>/dev/null || echo "0")

# 10. Format and Assemble JSON Report
PARSED_HEALTH_JSON="{}"
if [[ "${API_HEALTH_OK}" == "true" ]]; then
  if echo "${API_HEALTH_BODY}" | jq . >/dev/null 2>&1; then
    PARSED_HEALTH_JSON="${API_HEALTH_BODY}"
  fi
fi

PARSED_DEV_JSON="{}"
if [[ "${DEVICE_STATUS_OK}" == "true" ]]; then
  if echo "${DEV_BODY}" | jq . >/dev/null 2>&1; then
    PARSED_DEV_JSON="${DEV_BODY}"
  fi
fi

if command -v jq &>/dev/null; then
FINAL_REPORT=$(jq -n \
  --arg audit_id "${AUDIT_ID}" \
  --arg timestamp "${TIMESTAMP}" \
  --arg host "${TARGET_HOST}" \
  --argjson port "${TARGET_PORT}" \
  --arg overall_status "${OVERALL_STATUS}" \
  --argjson port_reachable "${PORT_REACHABLE}" \
  --arg port_latency_ms "${PORT_LATENCY_MS}" \
  --argjson security_enforced "${SECURITY_REJECTION_OK}" \
  --argjson security_code "${SECURITY_UNAUTH_CODE}" \
  --argjson health_ok "${API_HEALTH_OK}" \
  --argjson health_code "${API_HEALTH_STATUS}" \
  --arg health_latency_ms "${API_HEALTH_LATENCY_MS}" \
  --argjson dev_ok "${DEVICE_STATUS_OK}" \
  --argjson dev_code "${DEVICE_STATUS_CODE}" \
  --arg dev_latency_ms "${DEVICE_STATUS_LATENCY_MS}" \
  --argjson dns_resolved "${DNS_RESOLVED}" \
  --arg dns_latency_ms "${DNS_LATENCY_MS}" \
  --argjson token_exists "${TOKEN_FILE_EXISTS}" \
  --arg token_perms "${TOKEN_FILE_PERMS}" \
  --argjson token_secure "${TOKEN_SECURE}" \
  --arg uptime_sec "${UPTIME_SEC}" \
  --arg load_avg "${LOAD_AVG}" \
  --arg mem_free_mb "${MEM_FREE_MB}" \
  --argjson health_data "${PARSED_HEALTH_JSON}" \
  --argjson dev_data "${PARSED_DEV_JSON}" \
  '{
    audit_id: $audit_id,
    timestamp: $timestamp,
    environment: "kali-nethunter-rootless",
    target: {
      host: $host,
      port: $port,
      base_url: ("http://" + $host + ":" + ($port|tostring))
    },
    status: $overall_status,
    network_checks: {
      port_reachability: {
        reachable: $port_reachable,
        latency_ms: ($port_latency_ms | tonumber)
      },
      dns_resolution: {
        resolved: $dns_resolved,
        latency_ms: ($dns_latency_ms | tonumber)
      }
    },
    security_checks: {
      zero_trust_unauthenticated_rejection: {
        enforced: $security_enforced,
        expected_code: 401,
        actual_code: $security_code
      },
      token_storage: {
        exists: $token_exists,
        permissions: $token_perms,
        is_secure: $token_secure
      }
    },
    api_benchmarks: {
      health_endpoint: {
        success: $health_ok,
        status_code: $health_code,
        latency_ms: ($health_latency_ms | tonumber),
        server_uptime: ($health_data.uptime // null),
        memory_usage: ($health_data.memory // null)
      },
      device_status_endpoint: {
        success: $dev_ok,
        status_code: $dev_code,
        latency_ms: ($dev_latency_ms | tonumber),
        battery: ($dev_data.battery // null),
        wifi: ($dev_data.wifi // null)
      }
    },
    host_system_metrics: {
      uptime_seconds: ($uptime_sec | tonumber),
      load_average: $load_avg,
      free_memory_mb: ($mem_free_mb | tonumber)
    }
  }')
else
FINAL_REPORT=$(AUDIT_ID="${AUDIT_ID}" \
TIMESTAMP="${TIMESTAMP}" \
TARGET_HOST="${TARGET_HOST}" \
TARGET_PORT="${TARGET_PORT}" \
OVERALL_STATUS="${OVERALL_STATUS}" \
PORT_REACHABLE="${PORT_REACHABLE}" \
PORT_LATENCY_MS="${PORT_LATENCY_MS}" \
SECURITY_REJECTION_OK="${SECURITY_REJECTION_OK}" \
SECURITY_UNAUTH_CODE="${SECURITY_UNAUTH_CODE}" \
API_HEALTH_OK="${API_HEALTH_OK}" \
API_HEALTH_STATUS="${API_HEALTH_STATUS}" \
API_HEALTH_LATENCY_MS="${API_HEALTH_LATENCY_MS}" \
DEVICE_STATUS_OK="${DEVICE_STATUS_OK}" \
DEVICE_STATUS_CODE="${DEVICE_STATUS_CODE}" \
DEVICE_STATUS_LATENCY_MS="${DEVICE_STATUS_LATENCY_MS}" \
DNS_RESOLVED="${DNS_RESOLVED}" \
DNS_LATENCY_MS="${DNS_LATENCY_MS}" \
TOKEN_FILE_EXISTS="${TOKEN_FILE_EXISTS}" \
TOKEN_FILE_PERMS="${TOKEN_FILE_PERMS}" \
TOKEN_SECURE="${TOKEN_SECURE}" \
UPTIME_SEC="${UPTIME_SEC}" \
LOAD_AVG="${LOAD_AVG}" \
MEM_FREE_MB="${MEM_FREE_MB}" \
PARSED_HEALTH_JSON="${PARSED_HEALTH_JSON}" \
PARSED_DEV_JSON="${PARSED_DEV_JSON}" \
node -e '
  const e = process.env;
  let hData = null;
  let dData = null;
  try { hData = JSON.parse(e.PARSED_HEALTH_JSON); } catch(_) {}
  try { dData = JSON.parse(e.PARSED_DEV_JSON); } catch(_) {}
  const rep = {
    audit_id: e.AUDIT_ID,
    timestamp: e.TIMESTAMP,
    environment: "kali-nethunter-rootless",
    target: {
      host: e.TARGET_HOST,
      port: parseInt(e.TARGET_PORT, 10),
      base_url: "http://" + e.TARGET_HOST + ":" + e.TARGET_PORT
    },
    status: e.OVERALL_STATUS,
    network_checks: {
      port_reachability: {
        reachable: e.PORT_REACHABLE === "true",
        latency_ms: parseFloat(e.PORT_LATENCY_MS) || 0
      },
      dns_resolution: {
        resolved: e.DNS_RESOLVED === "true",
        latency_ms: parseFloat(e.DNS_LATENCY_MS) || 0
      }
    },
    security_checks: {
      zero_trust_unauthenticated_rejection: {
        enforced: e.SECURITY_REJECTION_OK === "true",
        expected_code: 401,
        actual_code: parseInt(e.SECURITY_UNAUTH_CODE, 10) || 0
      },
      token_storage: {
        exists: e.TOKEN_FILE_EXISTS === "true",
        permissions: e.TOKEN_FILE_PERMS,
        is_secure: e.TOKEN_SECURE === "true"
      }
    },
    api_benchmarks: {
      health_endpoint: {
        success: e.API_HEALTH_OK === "true",
        status_code: parseInt(e.API_HEALTH_STATUS, 10) || 0,
        latency_ms: parseFloat(e.API_HEALTH_LATENCY_MS) || 0,
        server_uptime: hData?.uptime || null,
        memory_usage: hData?.memory || null
      },
      device_status_endpoint: {
        success: e.DEVICE_STATUS_OK === "true",
        status_code: parseInt(e.DEVICE_STATUS_CODE, 10) || 0,
        latency_ms: parseFloat(e.DEVICE_STATUS_LATENCY_MS) || 0,
        battery: dData?.battery || null,
        wifi: dData?.wifi || null
      }
    },
    host_system_metrics: {
      uptime_seconds: parseInt(e.UPTIME_SEC, 10) || 0,
      load_average: e.LOAD_AVG,
      free_memory_mb: parseFloat(e.MEM_FREE_MB) || 0
    }
  };
  console.log(JSON.stringify(rep, null, 2));
')
fi

# 11. Write Report to Target Locations
LATEST_REPORT_PATH="${REPORT_DIR}/audit_latest.json"
TIMESTAMP_REPORT_PATH="${REPORT_DIR}/audit_$(date +%Y%m%d_%H%M%S).json"

echo "${FINAL_REPORT}" > "${LATEST_REPORT_PATH}"
echo "${FINAL_REPORT}" > "${TIMESTAMP_REPORT_PATH}"

if [[ -n "${OUTPUT_ARG}" ]]; then
  echo "${FINAL_REPORT}" > "${OUTPUT_ARG}"
  log_ok "Report saved to custom path: ${OUTPUT_ARG}"
fi

log_ok "Audit complete. Latest report saved to ${LATEST_REPORT_PATH}"

# Emit JSON to stdout
echo "${FINAL_REPORT}"

if [[ "${OVERALL_STATUS}" == "CRITICAL" ]]; then
  exit 1
fi

exit 0
