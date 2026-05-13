#!/usr/bin/env bash
set -euo pipefail

QUALYS_CUSTOMER_ID="${QUALYS_CUSTOMER_ID:?QUALYS_CUSTOMER_ID must be set}"
QUALYS_ACTIVATION_ID="${QUALYS_ACTIVATION_ID:?QUALYS_ACTIVATION_ID must be set}"
QUALYS_AGENT_URL="${QUALYS_AGENT_URL:-}"

echo "==> Installing Qualys Cloud Agent (GoldenImage mode)"

if [[ -n "${QUALYS_AGENT_URL}" ]]; then
    if [[ "${QUALYS_AGENT_URL}" == s3://* ]]; then
        echo "==> Downloading agent from S3"
        aws s3 cp "${QUALYS_AGENT_URL}" /tmp/qualys-cloud-agent.rpm
    else
        echo "==> Downloading agent from URL"
        curl -sSfL "${QUALYS_AGENT_URL}" -o /tmp/qualys-cloud-agent.rpm
    fi
else
    echo "ERROR: QUALYS_AGENT_URL must be set to the Cloud Agent installer location"
    exit 1
fi

if command -v dpkg &> /dev/null; then
    echo "==> Installing Cloud Agent (Debian)"
    sudo dpkg --install /tmp/qualys-cloud-agent.rpm
elif command -v rpm &> /dev/null; then
    echo "==> Installing Cloud Agent (RPM)"
    sudo rpm -ivh /tmp/qualys-cloud-agent.rpm
else
    echo "ERROR: No supported package manager found (dpkg or rpm)"
    exit 1
fi

echo "==> Configuring Cloud Agent with ActivationId and CustomerId"
sudo /usr/local/qualys/cloud-agent/bin/qualys-cloud-agent.sh \
    ActivationId="${QUALYS_ACTIVATION_ID}" \
    CustomerId="${QUALYS_CUSTOMER_ID}"

echo "==> Stopping Cloud Agent (GoldenImage mode - agent will activate on first boot of cloned instances)"
sudo service qualys-cloud-agent stop

rm -f /tmp/qualys-cloud-agent.rpm

echo "==> Qualys Cloud Agent installed in GoldenImage mode"
