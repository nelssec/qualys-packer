#!/usr/bin/env bash
set -uo pipefail

QUALYS_POD="${QUALYS_POD:?QUALYS_POD must be set}"
QUALYS_MODE="${QUALYS_MODE:-get-report}"
QUALYS_SCAN_TYPES="${QUALYS_SCAN_TYPES:-pkg,fileinsight}"
QUALYS_REPORT_FORMAT="${QUALYS_REPORT_FORMAT:-table,sarif}"
QUALYS_EXCLUDE_DIRS="${QUALYS_EXCLUDE_DIRS:-/proc,/sys,/dev,/run,/tmp}"
QUALYS_SCAN_TIMEOUT="${QUALYS_SCAN_TIMEOUT:-5m}"
QUALYS_POLICY_TAGS="${QUALYS_POLICY_TAGS:-}"
QUALYS_ASSET_NAME="${QUALYS_ASSET_NAME:-}"
FAIL_ON_AUDIT="${FAIL_ON_AUDIT:-false}"

OUTPUT_DIR="/tmp/qscanner-output"
mkdir -p "${OUTPUT_DIR}"

echo "==> Running QScanner scan"
echo "    Mode:       ${QUALYS_MODE}"
echo "    Scan types: ${QUALYS_SCAN_TYPES}"
echo "    Pod:        ${QUALYS_POD}"

CMD=(/tmp/qscanner
    --pod "${QUALYS_POD}"
    --access-token "${QUALYS_ACCESS_TOKEN}"
    --mode "${QUALYS_MODE}"
    --scan-types "${QUALYS_SCAN_TYPES}"
    --report-format "${QUALYS_REPORT_FORMAT}"
    --exclude-dirs "${QUALYS_EXCLUDE_DIRS}"
    --scan-timeout "${QUALYS_SCAN_TIMEOUT}"
    --shell-commands "uname -a=$(uname -a)"
    --output-dir "${OUTPUT_DIR}"
)

if [[ -n "${QUALYS_ASSET_NAME}" ]]; then
    CMD+=(--scan-target-info "asset_name=${QUALYS_ASSET_NAME}")
    CMD+=(--scan-target-info "provider_name=AWS")
    ACCOUNT_ID=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document 2>/dev/null | grep -o '"accountId" *: *"[^"]*"' | grep -o '[0-9]*' || echo "")
    if [[ -n "${ACCOUNT_ID}" ]]; then
        CMD+=(--scan-target-info "asset_tag=${ACCOUNT_ID}")
    fi
fi

if [[ -n "${QUALYS_POLICY_TAGS}" ]]; then
    CMD+=(--policy-tags "${QUALYS_POLICY_TAGS}")
fi

CMD+=(rootfs /)

echo "==> Executing: ${CMD[*]//${QUALYS_ACCESS_TOKEN}/[REDACTED]}"
"${CMD[@]}"
SCAN_EXIT_CODE=$?

echo "==> QScanner exited with code: ${SCAN_EXIT_CODE}"
echo "==> Scan artifacts:"
ls -la "${OUTPUT_DIR}/" 2>/dev/null || echo "    (none)"

if [[ "${QUALYS_MODE}" == "evaluate-policy" ]]; then
    case ${SCAN_EXIT_CODE} in
        0)
            echo "==> Policy evaluation: ALLOW"
            exit 0
            ;;
        42)
            echo "==> Policy evaluation: DENY - build will FAIL"
            exit 1
            ;;
        43)
            if [[ "${FAIL_ON_AUDIT}" == "true" ]]; then
                echo "==> Policy evaluation: AUDIT - build will FAIL (fail_on_audit=true)"
                exit 1
            else
                echo "==> Policy evaluation: AUDIT - continuing"
                exit 0
            fi
            ;;
        *)
            echo "==> QScanner error (exit code ${SCAN_EXIT_CODE}) - build will FAIL"
            exit 1
            ;;
    esac
else
    if [[ ${SCAN_EXIT_CODE} -ne 0 ]]; then
        echo "==> WARNING: QScanner exited with code ${SCAN_EXIT_CODE}, but mode is '${QUALYS_MODE}' so build continues"
    fi
    exit 0
fi
