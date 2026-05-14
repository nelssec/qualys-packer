#!/usr/bin/env bash
set -euo pipefail

QUALYS_CUSTOMER_ID="${QUALYS_CUSTOMER_ID:?QUALYS_CUSTOMER_ID must be set}"
QUALYS_ACTIVATION_ID="${QUALYS_ACTIVATION_ID:?QUALYS_ACTIVATION_ID must be set}"
QUALYS_AGENT_URL="${QUALYS_AGENT_URL:?QUALYS_AGENT_URL must be set}"
QUALYS_SERVER_URI="${QUALYS_SERVER_URI:-}"
PATCH_WAIT_TIMEOUT="${PATCH_WAIT_TIMEOUT:-600}"
PATCH_POLL_INTERVAL="${PATCH_POLL_INTERVAL:-30}"

echo "==> Phase 1: Install Qualys Cloud Agent"

AGENT_PKG="/tmp/qualys-cloud-agent"

if [[ "${QUALYS_AGENT_URL}" == s3://* ]]; then
    aws s3 cp "${QUALYS_AGENT_URL}" "${AGENT_PKG}"
else
    curl -sSfL "${QUALYS_AGENT_URL}" -o "${AGENT_PKG}"
fi

if command -v dpkg &> /dev/null; then
    echo "==> Installing Cloud Agent (Debian/Ubuntu)"
    sudo dpkg --install "${AGENT_PKG}"
elif command -v rpm &> /dev/null; then
    echo "==> Installing Cloud Agent (RHEL/Amazon Linux)"
    sudo rpm -ivh "${AGENT_PKG}"
else
    echo "ERROR: No supported package manager found"
    exit 1
fi

rm -f "${AGENT_PKG}"

echo "==> Phase 2: Activate Cloud Agent"
ACTIVATE_CMD="ActivationId=${QUALYS_ACTIVATION_ID} CustomerId=${QUALYS_CUSTOMER_ID}"
if [[ -n "${QUALYS_SERVER_URI}" ]]; then
    ACTIVATE_CMD="${ACTIVATE_CMD} ServerUri=${QUALYS_SERVER_URI}"
fi
# shellcheck disable=SC2086
sudo /usr/local/qualys/cloud-agent/bin/qualys-cloud-agent.sh ${ACTIVATE_CMD}

echo "==> Phase 3: Wait for agent to connect and scan"
ELAPSED=0
while [[ ${ELAPSED} -lt ${PATCH_WAIT_TIMEOUT} ]]; do
    AGENT_STATUS=$(sudo /usr/local/qualys/cloud-agent/bin/qualys-cloud-agent.sh Status 2>/dev/null || echo "unknown")
    echo "    [${ELAPSED}s] Agent status: ${AGENT_STATUS}"

    if echo "${AGENT_STATUS}" | grep -qi "connected\|provisioned\|running"; then
        echo "==> Agent connected to Qualys platform"
        break
    fi

    sleep "${PATCH_POLL_INTERVAL}"
    ELAPSED=$((ELAPSED + PATCH_POLL_INTERVAL))
done

if [[ ${ELAPSED} -ge ${PATCH_WAIT_TIMEOUT} ]]; then
    echo "WARNING: Agent did not connect within ${PATCH_WAIT_TIMEOUT}s, continuing anyway"
fi

echo "==> Phase 4: Wait for patching to complete"
echo "    Qualys Patch Management will deploy patches automatically"
echo "    Waiting up to ${PATCH_WAIT_TIMEOUT}s for patches to apply..."

ELAPSED=0
LAST_PATCH_COUNT=""
STABLE_COUNT=0
while [[ ${ELAPSED} -lt ${PATCH_WAIT_TIMEOUT} ]]; do
    PATCH_COUNT=$(rpm -qa --last 2>/dev/null | head -20 | wc -l || echo "0")

    if [[ "${PATCH_COUNT}" == "${LAST_PATCH_COUNT}" ]]; then
        STABLE_COUNT=$((STABLE_COUNT + 1))
    else
        STABLE_COUNT=0
    fi
    LAST_PATCH_COUNT="${PATCH_COUNT}"

    echo "    [${ELAPSED}s] Recent packages: ${PATCH_COUNT} (stable for ${STABLE_COUNT} checks)"

    if [[ ${STABLE_COUNT} -ge 3 && ${ELAPSED} -ge 120 ]]; then
        echo "==> Package state stable for 3 consecutive checks, patches likely complete"
        break
    fi

    sleep "${PATCH_POLL_INTERVAL}"
    ELAPSED=$((ELAPSED + PATCH_POLL_INTERVAL))
done

echo "==> Phase 5: Prepare golden image"
echo "    Stopping agent and clearing identity for clean clone provisioning"

sudo service qualys-cloud-agent stop

sudo rm -f /etc/qualys/hostid
sudo rm -f /etc/qualys/cloud-agent/setup/uuid
sudo rm -rf /var/log/qualys/*

echo "    Agent stopped"
echo "    Identity files cleared (hostid, uuid)"
echo "    Agent logs cleared"
echo ""
echo "==> Golden image ready"
echo "    On clone boot:"
echo "    - Agent starts automatically"
echo "    - Provisions with a unique identity"
echo "    - VDI: Asset Identification Service deduplicates clones"
echo "    - VMDR scans continuously"
echo "    - Patch Management deploys patches on schedule"
