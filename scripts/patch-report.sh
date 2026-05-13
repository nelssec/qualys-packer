#!/usr/bin/env bash
set -uo pipefail

OUTPUT_DIR="${OUTPUT_DIR:-/tmp/qscanner-output}"

REPORT=$(find "${OUTPUT_DIR}" -name "*-ScanResult.json" -type f | head -1)

if [[ -z "${REPORT}" ]]; then
    echo "==> No scan result found in ${OUTPUT_DIR}"
    exit 0
fi

echo "==> Generating patch remediation report from ${REPORT}"

python3 -c "
import json, sys

with open('${REPORT}') as f:
    data = json.load(f)

vulns = data.get('Vulnerabilities', [])
if not vulns:
    print('No vulnerabilities found.')
    sys.exit(0)

print(f'Total vulnerabilities: {len(vulns)}')
print()

by_package = {}
for v in vulns:
    qid = v.get('Qid', 'unknown')
    severity = v.get('Severity', 0)
    title = v.get('Title', '')
    cves = [c.get('Id', '') for c in v.get('Cves', [])]
    for sw in v.get('Software', []):
        name = sw.get('Name', 'unknown')
        installed = sw.get('InstalledVersion', 'unknown')
        fix = sw.get('FixVersion', 'N/A')
        key = f'{name}:{installed}'
        if key not in by_package:
            by_package[key] = {
                'name': name,
                'installed': installed,
                'fixes': set(),
                'qids': [],
                'cves': [],
                'max_severity': 0
            }
        if fix and fix != 'N/A':
            by_package[key]['fixes'].add(fix)
        by_package[key]['qids'].append(str(qid))
        by_package[key]['cves'].extend(cves)
        if severity > by_package[key]['max_severity']:
            by_package[key]['max_severity'] = severity

sorted_pkgs = sorted(by_package.values(), key=lambda x: -x['max_severity'])

print('REMEDIATION SUMMARY')
print('=' * 80)
print(f'{\"PACKAGE\":<25} {\"INSTALLED\":<15} {\"FIX TO\":<15} {\"SEV\":<5} {\"CVEs\":<5} {\"QIDs\"}')
print('-' * 80)

for pkg in sorted_pkgs:
    fix_versions = sorted(pkg['fixes'], reverse=True)
    latest_fix = fix_versions[0] if fix_versions else 'N/A'
    unique_cves = len(set(pkg['cves']))
    unique_qids = len(set(pkg['qids']))
    print(f'{pkg[\"name\"]:<25} {pkg[\"installed\"]:<15} {latest_fix:<15} {pkg[\"max_severity\"]:<5} {unique_cves:<5} {unique_qids}')

print()
print('UPGRADE COMMANDS')
print('=' * 80)
for pkg in sorted_pkgs:
    fix_versions = sorted(pkg['fixes'], reverse=True)
    if fix_versions:
        print(f'pip install {pkg[\"name\"]}=={fix_versions[0]}')
" 2>&1

echo ""
echo "==> Patch report complete"
