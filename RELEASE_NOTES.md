# Release Notes — AWS Cloud Security Baseline

## What This Project Demonstrates
- Least-privilege IAM personas (Admin / Developer / Read-only) implemented as Terraform.
- Audit-grade logging: CloudTrail to hardened S3 + CloudWatch Logs with retention; VPC Flow Logs to CloudWatch Logs with retention.
- Detection baseline: GuardDuty + Security Hub (AWS FSBP standard) with findings captured as evidence.
- AWS Config dependency for Security Hub controls (recorder + delivery channel + hardened S3 archive).
- Reproducible “bad → fixed” remediation demos with before/after proof and cleanup steps.

## Reproduce in <10 Minutes
Follow `README.md` for the full walkthrough:
- Deploy baseline: `README.md` (Deploy section)
- Detection + evidence: `evidence/03-detection-findings.md`
- Remediations (safe demos):
  - SG open SSH: `evidence/04-remediation-1-sg-open.md`
  - S3 public access: `evidence/05-remediation-2-s3-public.md`
  - IAM wildcard: `evidence/06-remediation-3-iam-wildcards.md`
- Incident runbook: `runbooks/guardduty-triage.md`

Helper scripts (print commands by default):
- `scripts/collect_evidence.ps1` / `scripts/collect_evidence.sh`
- `scripts/simulate_findings.ps1` / `scripts/simulate_findings.sh`

## Safety / Cost Notes
- This deploys billable AWS services (CloudTrail, CloudWatch Logs, S3 storage, GuardDuty, Security Hub, AWS Config).
- Demos intentionally create temporary misconfigurations; each remediation doc includes cleanup steps.
- Use a sandbox account and enable AWS Budget alerts before deploying.

## Teardown
- `terraform destroy` (from `terraform/`)
- If S3 buckets block teardown due to stored logs, either empty them manually or use: `terraform destroy -var="force_destroy_buckets=true"` (sandbox only).
