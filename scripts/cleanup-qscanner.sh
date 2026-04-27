#!/usr/bin/env bash
set -euo pipefail

echo "==> Cleaning up QScanner artifacts"

rm -f /tmp/qscanner
rm -rf /tmp/qscanner-install
rm -rf /tmp/qscanner-output
rm -rf ~/.cache/qualys/qscanner
rm -rf ~/qualys/qscanner/data

echo "==> QScanner cleanup complete"
