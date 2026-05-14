#!/usr/bin/env bash
set -euo pipefail

QUALYS_CUSTOMER_ID="${QUALYS_CUSTOMER_ID:?QUALYS_CUSTOMER_ID must be set}"
QUALYS_ACTIVATION_ID="${QUALYS_ACTIVATION_ID:?QUALYS_ACTIVATION_ID must be set}"
QUALYS_SERVER_URI="${QUALYS_SERVER_URI:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_PKG="/tmp/qualys-cloud-agent"

echo "==> Installing Qualys Cloud Agent (GoldenImage mode)"

bash "${SCRIPT_DIR}/download-cloud-agent.sh"

echo "==> Blocking Qualys platform connectivity during install"
echo "127.0.0.1 qualysguard.qualys.com" | sudo tee -a /etc/hosts > /dev/null

if command -v dpkg &> /dev/null; then
    sudo dpkg --install "${AGENT_PKG}"
elif command -v rpm &> /dev/null; then
    sudo rpm -ivh "${AGENT_PKG}"
else
    echo "ERROR: No supported package manager found"
    exit 1
fi
rm -f "${AGENT_PKG}"

echo "==> Configuring Cloud Agent"
ACTIVATE_CMD="ActivationId=${QUALYS_ACTIVATION_ID} CustomerId=${QUALYS_CUSTOMER_ID}"
if [[ -n "${QUALYS_SERVER_URI}" ]]; then
    ACTIVATE_CMD="${ACTIVATE_CMD} ServerUri=${QUALYS_SERVER_URI}"
fi
# shellcheck disable=SC2086
sudo /usr/local/qualys/cloud-agent/bin/qualys-cloud-agent.sh ${ACTIVATE_CMD}

echo "==> Stopping Cloud Agent"
sudo service qualys-cloud-agent stop

echo "==> Removing network block"
sudo sed -i '/qualysguard.qualys.com/d' /etc/hosts

echo "==> Cleaning up for golden image"
sudo rm -rf /var/log/qualys/*

echo "==> Cloud Agent installed in GoldenImage mode"
echo "    Agent is configured but has NOT provisioned (no UUID generated)"
echo "    On clone boot: agent starts, connects, gets unique identity"
