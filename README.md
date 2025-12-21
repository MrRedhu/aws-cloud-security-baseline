# AWS Cloud Security Baseline (IAM + Logging + Detection + Remediation)

A secure-by-default AWS baseline that demonstrates **least-privilege IAM**, **centralized and hardened logging**, **threat detection (GuardDuty + Security Hub)**, and **evidence-backed remediations**.  
This repo is designed to be **deployable, reproducible, and auditable** - similar to what cloud security teams ship as an internal baseline.

## Why this matters
- Most real-world cloud incidents start with over-permissioned IAM, missing audit logs, or weak detections.
- This baseline shows how to build those controls as code, then prove them with repeatable evidence.

## What this proves
- IAM design for **realistic personas** (Admin / Developer / Read-only) using least privilege
- Audit-grade **logging pipeline** (CloudTrail + VPC Flow Logs + CloudWatch + hardened S3)
- **Detection** enabled and validated using safe simulations
- **Remediation** workflows with before/after evidence
- Incident response thinking via a short **runbook**

## Architecture (high level)

```mermaid
flowchart TB
  subgraph Identity["Identity & Access (Least Privilege)"]
    Admin[Admin Persona] --> AR[(Admin Role)]
    Dev[Developer Persona] --> DR[(Developer Role)]
    RO[Read-only Persona] --> RR[(ReadOnly Role)]
  end

  subgraph Logging["Logging (Centralized + Retention + Hardened Storage)"]
    CT[CloudTrail] --> CWL[CloudWatch Logs\n(retention set)]
    VPC[VPC Flow Logs] --> CWL
    CT --> S3[(Central Log Bucket)]
    CWL --> S3
    S3 --> Hardened[Hardened Storage\nBlock Public Access + Encryption + Versioning]
  end

  subgraph Detection["Detection (Signals + Findings)"]
    GD[GuardDuty] --> SH[Security Hub]
    SH --> Findings[Findings\n(JSON + screenshots as evidence)]
  end
```

## What Gets Deployed
- **IAM personas**: Admin / Developer / ReadOnly roles + example bad vs fixed policy
- **Logging baseline**: CloudTrail (S3 + CloudWatch Logs), CloudWatch retention, hardened S3 log archive, VPC Flow Logs to CloudWatch
- **Detection baseline**: GuardDuty + Security Hub (AWS FSBP standard)
- **Config dependency**: AWS Config recorder + delivery channel + hardened S3 archive (required for Security Hub controls)

---

## Repo navigation
- Environment + guardrails: `evidence/00-environment.md`
- Architecture diagram source: `diagrams/architecture.mmd`
- Incident runbook (template): `runbooks/guardduty-triage.md`

## Evidence links
- IAM: `evidence/01-iam-before-after.md`
- Logging: `evidence/02-logging-before-after.md`
- Detection: `evidence/03-detection-findings.md`
- Remediation 1 (SG open SSH): `evidence/04-remediation-1-sg-open.md`
- Remediation 2 (S3 public access): `evidence/05-remediation-2-s3-public.md`
- Remediation 3 (IAM wildcard): `evidence/06-remediation-3-iam-wildcards.md`
- Runbook: `runbooks/guardduty-triage.md`

## Reproduce (deploy → simulate → remediate → destroy)
### Prereqs
- Terraform `>= 1.5`
- AWS CLI authenticated to a sandbox account (region defaults to `us-east-1`)

### Deploy
```powershell
cd terraform
terraform init
terraform apply
terraform output
```

### Simulate + Remediate (safe demos)
Use the exact commands and captured outputs in:
- `evidence/04-remediation-1-sg-open.md` (Security Hub control `EC2.18`)
- `evidence/05-remediation-2-s3-public.md` (public S3 policy → blocked)
- `evidence/06-remediation-3-iam-wildcards.md` (bad wildcard → least privilege)

### Destroy
```powershell
cd terraform
terraform destroy
```
If destroy fails because S3 buckets contain logs, empty the buckets from `terraform output` (`log_bucket_name`, `config_bucket_name`) and re-run destroy:
```powershell
aws s3 rm s3://<bucket> --recursive
terraform destroy
```

## Cost & Safety Notes
- Enable a budget and use a dedicated sandbox account if possible.
- Ongoing costs can include CloudTrail, CloudWatch Logs ingestion/retention, S3 storage, GuardDuty, Security Hub, and AWS Config.
- All simulations are reversible misconfigurations only (no exploitation). Do not commit secrets.
