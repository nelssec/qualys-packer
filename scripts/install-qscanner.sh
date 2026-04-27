#!/usr/bin/env bash
set -euo pipefail

QSCANNER_VERSION="${QSCANNER_VERSION:-latest}"
INSTALL_DIR="/tmp/qscanner-install"

echo "==> Installing QScanner (${QSCANNER_VERSION})"

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

/tmp/qscanner --version
echo "==> QScanner installed successfully"
