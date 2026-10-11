#!/bin/sh
# ==============================================================================
# automation-intents.sh
# Android Intent & Notification Dispatcher for Mj-work-ai (Android Node Bridge)
# Security Model: Zero-Trust Parameterized Execution & Audit Logging
# ==============================================================================

set -eu

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config.json"
LOG_DIR="${SCRIPT_DIR}/logs"
LOG_FILE="${LOG_DIR}/gateway-automation.log"
MAX_LOG_SIZE=2097152 # 2MB threshold
MAX_BACKUPS=5

# Ensure logging directory exists
mkdir -p "${LOG_DIR}"

# --- Automatic Log Rotation ---
rotate_logs() {
    if [ -f "${LOG_FILE}" ]; then
        file_size=$(wc -c < "${LOG_FILE}" 2>/dev/null || echo 0)
        if [ "${file_size}" -ge "${MAX_LOG_SIZE}" ]; then
            i=$((MAX_BACKUPS - 1))
            while [ $i -ge 1 ]; do
                next=$((i + 1))
                if [ -f "${LOG_FILE}.${i}" ]; then
                    mv -f "${LOG_FILE}.${i}" "${LOG_FILE}.${next}"
                fi
                i=$((i - 1))
            done
            mv -f "${LOG_FILE}" "${LOG_FILE}.1"
            echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] [PID:$$] [INFO] Log rotated. Previous active log archived to ${LOG_FILE}.1" > "${LOG_FILE}"
        fi
    fi
}

log_event() {
    level="$1"
    msg="$2"
    rotate_logs
    printf '[%s] [PID:%d] [%s] %s\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "$$" "${level}" "${msg}" >> "${LOG_FILE}"
}

AM_BIN="$(command -v am 2>/dev/null || echo "/data/data/com.termux/files/usr/bin/am")"
if [ ! -x "${AM_BIN}" ] && [ -x "/system/bin/am" ]; then
    AM_BIN="/system/bin/am"
fi

TERMUX_NOTIFY_BIN="$(command -v termux-notification 2>/dev/null || echo "/data/data/com.termux/files/usr/bin/termux-notification")"

print_usage() {
    cat << 'EOF'
Usage: automation-intents.sh [OPTIONS]

Options:
  -a, --action <ACTION_NAME>        Dispatch pre-configured intent action
  -c, --component <COMPONENT>       Dispatch explicit component (e.g., pkg/.Activity)
  -t, --type <TYPE>                 Dispatch type: activity (default), broadcast, service
  -e, --extras <ARGS>               Optional extras passed directly to am (e.g. '--es key val')
  -n, --notify-critical <T> <M> [P] Dispatch immediate critical Android notification
  -l, --list                        List all pre-configured intent actions
  -j, --json                        Output result in JSON format
  -h, --help                        Display this help message

Registered Actions:
  netguard-logs      eu.faircode.netguard/.ActivityLog
  nextcloud-sync     com.nextcloud.client/.features.transfers.TransfersActivity
  kdeconnect-runner  org.kde.kdeconnect_tp/.SendFileActivity
  vernet-scan        org.fsociety.vernet/.MainActivity
  keepitup-status    net.ibbaa.keepitup/.ui.NetworkTaskMainActivity
  wolpanel-control   com.sasas991.wolpanel/.MainActivity
  meshtastic-alerts  com.geeksville.mesh/.MainActivity
  metadata-cleaner   rocks.poopjournal.metadataremover/.MainActivity
EOF
}

# Whitelist of allowed package prefixes for strict Zero-Trust containment
is_authorized_component() {
    target="$1"
    case "$target" in
        eu.faircode.netguard/*|\
        com.nextcloud.client/*|\
        org.kde.kdeconnect_tp/*|\
        org.fsociety.vernet/*|\
        net.ibbaa.keepitup/*|\
        jp.takke.datastats/*|\
        com.sasas991.wolpanel/*|\
        com.geeksville.mesh/*|\
        rocks.poopjournal.metadataremover/*|\
        si.jakobkreft.exifremove/*|\
        com.emanuelef.remote_capture/*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

resolve_action_component() {
    act="$1"
    case "$act" in
        netguard-logs)
            echo "eu.faircode.netguard/.ActivityLog"
            ;;
        nextcloud-sync)
            echo "com.nextcloud.client/.features.transfers.TransfersActivity"
            ;;
        kdeconnect-runner)
            echo "org.kde.kdeconnect_tp/.SendFileActivity"
            ;;
        vernet-scan)
            echo "org.fsociety.vernet/.MainActivity"
            ;;
        keepitup-status)
            echo "net.ibbaa.keepitup/.ui.NetworkTaskMainActivity"
            ;;
        wolpanel-control)
            echo "com.sasas991.wolpanel/.MainActivity"
            ;;
        meshtastic-alerts)
            echo "com.geeksville.mesh/.MainActivity"
            ;;
        metadata-cleaner)
            echo "rocks.poopjournal.metadataremover/.MainActivity"
            ;;
        *)
            echo ""
            ;;
    esac
}

list_actions() {
    cat << 'EOF'
ACTION              SUBSYSTEM   TARGET COMPONENT
netguard-logs       NETWORK     eu.faircode.netguard/.ActivityLog
nextcloud-sync      SECURITY    com.nextcloud.client/.features.transfers.TransfersActivity
kdeconnect-runner   CORE        org.kde.kdeconnect_tp/.SendFileActivity
vernet-scan         NETWORK     org.fsociety.vernet/.MainActivity
keepitup-status     CORE        net.ibbaa.keepitup/.ui.NetworkTaskMainActivity
wolpanel-control    CORE        com.sasas991.wolpanel/.MainActivity
meshtastic-alerts   SECURITY    com.geeksville.mesh/.MainActivity
metadata-cleaner    SECURITY    rocks.poopjournal.metadataremover/.MainActivity
EOF
}

dispatch_critical_notification() {
    title="$1"
    message="$2"
    priority="${3:-max}"
    timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    notif_id="mj-crit-$(date +%s)"

    log_event "CRITICAL_ALERT" "Dispatching critical notification: [${title}] ${message}"

    if [ -x "${TERMUX_NOTIFY_BIN}" ]; then
        if "${TERMUX_NOTIFY_BIN}" \
            --title "🚨 ${title}" \
            --content "${message}" \
            --priority "${priority}" \
            --id "${notif_id}" \
            --vibrate 500,200,500 \
            --sound 2>/dev/null; then
            log_event "INFO" "termux-notification successfully delivered (id: ${notif_id})"
            if [ "${OUTPUT_JSON}" -eq 1 ]; then
                printf '{"timestamp":"%s","status":"OK","type":"CRITICAL_NOTIFICATION","id":"%s","title":"%s","priority":"%s"}\n' \
                    "${timestamp}" "${notif_id}" "${title}" "${priority}"
            else
                echo "[OK] Critical alert delivered to Android display (id: ${notif_id})."
            fi
            return 0
        else
            log_event "WARN" "termux-notification failed; logged to file."
        fi
    else
        log_event "WARN" "termux-notification binary not found or not executable. Alert logged only."
    fi

    if [ "${OUTPUT_JSON}" -eq 1 ]; then
        printf '{"timestamp":"%s","status":"FALLBACK_LOGGED","type":"CRITICAL_NOTIFICATION","title":"%s","message":"%s"}\n' \
            "${timestamp}" "${title}" "${message}"
    else
        echo "[ALERT] (Fallback) [${title}] ${message}"
    fi
    return 0
}

ACTION=""
COMPONENT=""
DISPATCH_TYPE="activity"
EXTRAS=""
OUTPUT_JSON=0
NOTIFY_TITLE=""
NOTIFY_MSG=""
NOTIFY_PRIO="max"
DO_NOTIFY=0

while [ $# -gt 0 ]; do
    case "$1" in
        -a|--action)
            ACTION="$2"
            shift 2
            ;;
        -c|--component)
            COMPONENT="$2"
            shift 2
            ;;
        -t|--type)
            DISPATCH_TYPE="$2"
            shift 2
            ;;
        -e|--extras)
            EXTRAS="$2"
            shift 2
            ;;
        -n|--notify-critical)
            DO_NOTIFY=1
            NOTIFY_TITLE="$2"
            NOTIFY_MSG="$3"
            if [ $# -ge 4 ] && [ "${4#-}" = "$4" ]; then
                NOTIFY_PRIO="$4"
                shift 4
            else
                shift 3
            fi
            ;;
        -l|--list)
            list_actions
            exit 0
            ;;
        -j|--json)
            OUTPUT_JSON=1
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            print_usage >&2
            exit 1
            ;;
    esac
done

# If notification requested, execute and finish
if [ "${DO_NOTIFY}" -eq 1 ]; then
    dispatch_critical_notification "${NOTIFY_TITLE}" "${NOTIFY_MSG}" "${NOTIFY_PRIO}"
    exit 0
fi

if [ -z "${ACTION}" ] && [ -z "${COMPONENT}" ]; then
    echo "ERROR: Either --action, --component, or --notify-critical must be specified." >&2
    print_usage >&2
    exit 1
fi

if [ -n "${ACTION}" ]; then
    COMPONENT="$(resolve_action_component "${ACTION}")"
    if [ -z "${COMPONENT}" ]; then
        log_event "ERROR" "Unknown action requested: ${ACTION}"
        if [ $OUTPUT_JSON -eq 1 ]; then
            printf '{"status":"ERROR","message":"Unknown action: %s"}\n' "${ACTION}"
        else
            echo "ERROR: Action '${ACTION}' not recognized in registered catalog." >&2
        fi
        exit 2
    fi
fi

if ! is_authorized_component "${COMPONENT}"; then
    log_event "SECURITY_VIOLATION" "Component rejected by Zero-Trust whitelist: ${COMPONENT}"
    if [ $OUTPUT_JSON -eq 1 ]; then
        printf '{"status":"FORBIDDEN","code":403,"message":"Component violates Zero-Trust whitelist: %s"}\n' "${COMPONENT}"
    else
        echo "SECURITY ERROR: Component '${COMPONENT}' rejected. Violates Zero-Trust package inventory." >&2
    fi
    exit 43
fi

# Build execution command
AM_SUBCOMMAND="start"
case "${DISPATCH_TYPE}" in
    activity)
        AM_SUBCOMMAND="start -n"
        ;;
    broadcast)
        AM_SUBCOMMAND="broadcast -n"
        ;;
    service)
        AM_SUBCOMMAND="startservice -n"
        ;;
    *)
        log_event "ERROR" "Unsupported dispatch type: ${DISPATCH_TYPE}"
        echo "ERROR: Unsupported dispatch type: ${DISPATCH_TYPE}" >&2
        exit 3
        ;;
esac

CMD="${AM_BIN} ${AM_SUBCOMMAND} ${COMPONENT}"
if [ -n "${EXTRAS}" ]; then
    CMD="${CMD} ${EXTRAS}"
fi

TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
EXEC_OUT=""
EXEC_CODE=0

log_event "INTENT_DISPATCH" "Executing: ${CMD}"

if EXEC_OUT=$(sh -c "${CMD}" 2>&1); then
    EXEC_CODE=0
    log_event "INTENT_SUCCESS" "Dispatched '${COMPONENT}' successfully. Output: ${EXEC_OUT}"
else
    EXEC_CODE=$?
    log_event "INTENT_FAILED" "Failed dispatch '${COMPONENT}' (code: ${EXEC_CODE}). Stderr: ${EXEC_OUT}"
fi

if [ $OUTPUT_JSON -eq 1 ]; then
    ESCAPED_OUT=$(printf '%s' "${EXEC_OUT}" | sed 's/"/\\"/g' | tr '\n' ' ')
    printf '{"timestamp":"%s","status":"%s","code":%d,"action":"%s","component":"%s","output":"%s"}\n' \
        "${TIMESTAMP}" \
        "$([ $EXEC_CODE -eq 0 ] && echo "OK" || echo "ERROR")" \
        "${EXEC_CODE}" \
        "${ACTION:-custom}" \
        "${COMPONENT}" \
        "${ESCAPED_OUT}"
else
    if [ $EXEC_CODE -eq 0 ]; then
        echo "[OK] Dispatched '${COMPONENT}' successfully."
        [ -n "${EXEC_OUT}" ] && echo "${EXEC_OUT}"
    else
        echo "[FAILED] Failed to dispatch '${COMPONENT}' (Exit code: ${EXEC_CODE})." >&2
        [ -n "${EXEC_OUT}" ] && echo "${EXEC_OUT}" >&2
    fi
fi

exit ${EXEC_CODE}
