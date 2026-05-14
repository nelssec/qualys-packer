#!/usr/bin/env bash
set -euo pipefail

QUALYS_AGENT_URL="${QUALYS_AGENT_URL:-api}"
QUALYS_API_USERNAME="${QUALYS_API_USERNAME:-}"
QUALYS_API_PASSWORD="${QUALYS_API_PASSWORD:-}"
QUALYS_API_URL="${QUALYS_API_URL:-}"
AGENT_PKG="/tmp/qualys-cloud-agent"

echo "==> Downloading Qualys Cloud Agent"

if [[ "${QUALYS_AGENT_URL}" == "api" ]]; then
    if [[ -z "${QUALYS_API_USERNAME}" || -z "${QUALYS_API_PASSWORD}" ]]; then
        echo "ERROR: QUALYS_API_USERNAME and QUALYS_API_PASSWORD required when qualys_agent_url=api"
        exit 1
    fi
    if [[ -z "${QUALYS_API_URL}" ]]; then
        echo "ERROR: QUALYS_API_URL required when qualys_agent_url=api"
        exit 1
    fi

    ARCH=$(uname -m)
    case "${ARCH}" in
        x86_64|amd64) API_ARCH="X_86_64" ;;
        aarch64|arm64) API_ARCH="AARCH_64" ;;
        *) echo "ERROR: Unsupported architecture: ${ARCH}"; exit 1 ;;
    esac

    echo "    Source: Qualys API (${QUALYS_API_URL})"
    echo "    Platform: LINUX, Architecture: ${API_ARCH}"

    HTTP_CODE=$(curl -sSf -o "${AGENT_PKG}" -w "%{http_code}" \
        -u "${QUALYS_API_USERNAME}:${QUALYS_API_PASSWORD}" \
        -H "Content-Type: application/xml" \
        -d "<DownloadBinary><platform>LINUX</platform><architecture>${API_ARCH}</architecture></DownloadBinary>" \
        "${QUALYS_API_URL}/qps/rest/1.0/download/ca/downloadbinary" 2>&1) || true

    if [[ ! -f "${AGENT_PKG}" ]] || [[ $(stat -f%z "${AGENT_PKG}" 2>/dev/null || stat -c%s "${AGENT_PKG}" 2>/dev/null) -lt 1000 ]]; then
        echo "ERROR: Failed to download Cloud Agent from API (HTTP ${HTTP_CODE})"
        cat "${AGENT_PKG}" 2>/dev/null || true
        exit 1
    fi

elif [[ "${QUALYS_AGENT_URL}" == s3://* ]]; then
    echo "    Source: S3 (${QUALYS_AGENT_URL})"
    aws s3 cp "${QUALYS_AGENT_URL}" "${AGENT_PKG}"

else
    echo "    Source: URL"
    curl -sSfL "${QUALYS_AGENT_URL}" -o "${AGENT_PKG}"
fi

chmod +x "${AGENT_PKG}" 2>/dev/null || true
FILE_TYPE=$(file "${AGENT_PKG}" | head -1)
echo "    Downloaded: ${FILE_TYPE}"
echo "==> Cloud Agent download complete"
