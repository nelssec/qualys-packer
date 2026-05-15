#!/usr/bin/env bash
set -euo pipefail

QUALYS_API_USERNAME="${QUALYS_API_USERNAME:?QUALYS_API_USERNAME must be set}"
QUALYS_API_PASSWORD="${QUALYS_API_PASSWORD:?QUALYS_API_PASSWORD must be set}"
QUALYS_GATEWAY_URL="${QUALYS_GATEWAY_URL:?QUALYS_GATEWAY_URL must be set}"
QUALYS_CUSTOMER_ID="${QUALYS_CUSTOMER_ID:-}"
QUALYS_ACTIVATION_ID="${QUALYS_ACTIVATION_ID:-}"

echo "==> Resolving Qualys Customer ID and Activation ID"

JWT=$(curl -s -X POST \
    -H "X-Requested-With: curl" \
    -d "username=${QUALYS_API_USERNAME}&password=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${QUALYS_API_PASSWORD}', safe=''))")&token=true" \
    "${QUALYS_GATEWAY_URL}/auth" 2>&1)

if [[ -z "${JWT}" || "${JWT}" == *"error"* ]]; then
    echo "ERROR: Failed to get JWT from ${QUALYS_GATEWAY_URL}/auth"
    exit 1
fi

if [[ -z "${QUALYS_CUSTOMER_ID}" ]]; then
    QUALYS_CUSTOMER_ID=$(echo "${JWT}" | cut -d'.' -f2 | base64 -d 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('customerUuid',''))" 2>/dev/null)
    echo "    Customer ID (from JWT): ${QUALYS_CUSTOMER_ID}"
fi

if [[ -z "${QUALYS_ACTIVATION_ID}" ]]; then
    QUALYS_ACTIVATION_ID=$(curl -s \
        -H "Authorization: Bearer ${JWT}" \
        -H "Content-Type: application/json" \
        -H "X-Requested-With: curl" \
        "${QUALYS_GATEWAY_URL}/caui/v1/activation-keys/manage" \
        -d '{"pageSize":100}' 2>&1 | \
        python3 -c "
import sys, json
data = json.load(sys.stdin)
keys = data.get('content', [])
# Prefer keys with PM (Patch Management) + VM modules, unlimited, not disabled
best = None
for k in keys:
    if k.get('isDisabled'): continue
    licenses = k.get('licenses', [])
    has_pm = 'PM' in licenses
    has_vm = 'VM' in licenses
    if has_pm and has_vm:
        if best is None or len(licenses) > len(best.get('licenses', [])):
            best = k
if best is None:
    for k in keys:
        if not k.get('isDisabled'):
            best = k
            break
if best:
    print(best['activationKey'])
else:
    print('')
" 2>/dev/null)
    echo "    Activation ID (auto-selected): ${QUALYS_ACTIVATION_ID}"
fi

if [[ -z "${QUALYS_CUSTOMER_ID}" ]]; then
    echo "ERROR: Could not resolve Customer ID"
    exit 1
fi

if [[ -z "${QUALYS_ACTIVATION_ID}" ]]; then
    echo "ERROR: Could not resolve Activation ID"
    exit 1
fi

echo "    Customer ID:   ${QUALYS_CUSTOMER_ID}"
echo "    Activation ID: ${QUALYS_ACTIVATION_ID}"

export QUALYS_CUSTOMER_ID
export QUALYS_ACTIVATION_ID
