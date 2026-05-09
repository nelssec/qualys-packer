# Shift-Left Security: Building Vulnerability-Free Infrastructure from Source to Production

---

## Slide 1: The Gap That's Getting People Breached

Attackers exploit known vulnerabilities in 5 days. Defenders take 35-61 days to patch them.

| Metric | Number | Source |
|--------|--------|--------|
| Time to exploit a new vulnerability | **5 days** | CyberMindr 2025 |
| Time to remediate critical vulns (internet-facing) | **35 days** | Edgescan 2025 |
| Time to remediate critical vulns (host/cloud) | **61 days** | Edgescan 2025 |
| Breaches from known, patchable vulnerabilities | **60%** | Verizon DBIR 2025 |
| Enterprises that fail to patch critical vulns within 30 days | **52%** | DeepStrike 2025 |

The problem is not detection. The problem is where and when you detect.

Finding a vulnerability in production means you are already 30-60 days behind an attacker who found it in 5. Finding it during the build means it never reaches production.

---

## Slide 2: Every Layer Has a Problem

Modern infrastructure has four layers between source code and production. Each one has its own class of vulnerabilities, and most organizations only scan the last one.

**Source Code (SCA)**
- 512,847 malicious packages published to open-source registries in 2024 (156% YoY increase)
- 75% of organizations experienced a supply chain attack in the last year
- 30% of breaches now involve a third party (Verizon DBIR 2025)

**Infrastructure as Code**
- Misconfiguration is the #1 cloud threat (CSA 2024)
- 90% of cloud resources drift from their secure baseline after deployment
- 23% of cloud breaches are caused by misconfigurations

**Container Images**
- 87% of container images in production have critical or high vulnerabilities
- Average container has 604 known vulnerabilities
- Only 15% of those are in packages actually loaded at runtime

**Golden Images / AMIs**
- 291 OS packages on a stock Amazon Linux 2023 AMI, 48 language packages, 30 known vulnerabilities
- Every instance, auto scaling group, and launch template inherits whatever is in that base image
- 83% of organizations experienced at least one cloud security incident in 2024

Scanning only in production means you are scanning the wrong layer, too late, with too much noise.

---

## Slide 3: Shift Left Means Shift Into the Pipeline

The fix is not a new tool. It is scanning at the point where the artifact is created, inside the CI/CD pipeline, before it becomes an artifact anyone can deploy.

```
Source Code       IaC Templates       Container Images       Golden AMIs
    |                  |                    |                     |
    v                  v                    v                     v
 SCA Scan         Policy Scan         Image Scan            Rootfs Scan
 (commit)          (commit)           (build)               (build)
    |                  |                    |                     |
    v                  v                    v                     v
 Pass/Fail         Pass/Fail           Pass/Fail             Pass/Fail
```

Each scan runs as a native CI/CD step. GitHub Actions, Jenkins, GitLab CI. The developer pushes code, the pipeline scans, the build passes or fails. No separate scanning infrastructure. No manual review gates. No 35-day remediation window.

What makes this work:

- **Scan types match the artifact type.** SCA for code. Policy checks for Terraform. OS + SCA for containers and AMIs.
- **Results go where developers already look.** SARIF reports in the GitHub Security tab. Console output in Jenkins. Build artifacts for auditors.
- **Policy is centralized, enforcement is distributed.** Security teams define thresholds and rules. Pipelines enforce them automatically at build time.
- **Nothing is baked in.** Scanners are downloaded, used, and removed. No agents persist in production artifacts.

Organizations practicing shift-left security reduced critical vulnerabilities by up to 45%.

---

## Slide 4: What This Looks Like in Practice

A single golden AMI build with integrated vulnerability scanning. Real output from an Amazon Linux 2023 build on Jenkins:

```
OS detected: Amazon Linux 2023.11.20260505
OS packages detected: 291
Technologies detected: Python
Language packages detected: 48
FileInsight findings: 2
All scans completed in 2.2s

SBOM uploaded successfully
Changelist uploaded successfully
Vulnerability report received

30 vulnerabilities found
  Severity 5 (Critical): 1
  Severity 4 (High):     8
  Severity 3 (Medium):  17
  Severity 2 (Low):      4
```

That scan ran inside a Packer build provisioner. The scanner was downloaded onto the EC2 instance, scanned the root filesystem, uploaded results to the backend, received a vulnerability report, and was removed before the AMI snapshot. Total scan time: 2.2 seconds for data collection, under 4 minutes end-to-end including report retrieval.

The same pattern applies across the full stack:

| Layer | Trigger | Scan Time | Output |
|-------|---------|-----------|--------|
| Source code | `git push` | seconds | SARIF in GitHub Security tab |
| Terraform / CloudFormation | `git push` | seconds | Policy pass/fail + SARIF |
| Container image | `docker build` | seconds | Vuln report + SBOM (SPDX, CycloneDX) |
| Golden AMI | `packer build` | ~2 seconds scan, ~4 min total | Vuln report + SBOM + AMI tags |

In `evaluate-policy` mode, every one of these gates the build. If the policy says deny, the artifact is never created. A vulnerable AMI, a misconfigured Terraform module, a container with a critical CVE, a dependency with a known exploit -- none of them make it past the pipeline.

---

## Slide 5: The Full Pipeline

```
Developer Workstation
        |
        v
   Git Push / PR
        |
   +---------+-----------+-----------+
   |         |           |           |
   v         v           v           v
Code Scan  IaC Scan  Container   Golden AMI
  (SCA)   (TotalCloud)  Scan       (Packer)
   |         |           |           |
   v         v           v           v
GitHub    GitHub      GitHub      Jenkins /
Security  Security    Security    GitHub Actions
  Tab       Tab         Tab         Console
   |         |           |           |
   +----+----+-----+-----+-----+----+
        |          |           |
        v          v           v
   SARIF Reports  SBOMs    Vuln Reports
   (audit trail)  (SPDX,   (table, JSON,
                  CycloneDX) SARIF)
        |
        v
  Central Dashboard
  (single pane of glass across all artifact types)
```

What this gives you:

- **Every artifact is scanned before it exists.** Code at commit. IaC at commit. Images at build. AMIs at build.
- **Every scan produces an SBOM.** Full software bill of materials in SPDX or CycloneDX format. You know exactly what is in every artifact you deploy.
- **Policy enforcement is automatic.** No human approval gates. The pipeline enforces the same rules every time.
- **Remediation happens at the keyboard, not in production.** The developer who introduced the vulnerability sees it in the PR, not in a ticket 35 days later.
- **Audit trail is built in.** SARIF reports, SBOMs, vulnerability reports -- all archived as build artifacts.

The cost of fixing a defect in design is $80. In production, it is $7,600. The question is not whether to shift left. The question is how many layers you are covering.
