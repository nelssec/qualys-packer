#!/usr/bin/env bash
set -euo pipefail

QSCANNER_VERSION="${QSCANNER_VERSION:-latest}"
QSCANNER_S3_URL="${QSCANNER_S3_URL:-}"

echo "==> Installing QScanner (${QSCANNER_VERSION})"

if [[ -n "${QSCANNER_S3_URL}" ]]; then
    if [[ "${QSCANNER_S3_URL}" == s3://* ]]; then
        echo "==> Downloading from S3: ${QSCANNER_S3_URL}"
        aws s3 cp "${QSCANNER_S3_URL}" /tmp/qscanner
    else
        echo "==> Downloading from URL"
        curl -sSfL "${QSCANNER_S3_URL}" -o /tmp/qscanner
    fi
    chmod +x /tmp/qscanner
else
    INSTALL_DIR="/tmp/qscanner-install"
    mkdir -p "${INSTALL_DIR}"
    cd "${INSTALL_DIR}"

    curl -sSfLO "https://www.qualys.com/qscanner/download/${QSCANNER_VERSION}/download_qscanner.sh"
    chmod +x download_qscanner.sh
    bash download_qscanner.sh

    BINARY_PATH=$(find "${INSTALL_DIR}" -name "qscanner" -type f | head -1)

    if [[ -z "${BINARY_PATH}" ]]; then
        echo "ERROR: QScanner binary not found after download"
        exit 1
    fi

    cp "${BINARY_PATH}" /tmp/qscanner
    chmod +x /tmp/qscanner
fi

/tmp/qscanner --version
echo "==> QScanner installed successfully"
