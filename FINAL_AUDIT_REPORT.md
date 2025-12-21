# Final Audit Report — AWS Cloud Security Baseline

Audit scope: README + Terraform + evidence + scripts (public-facing, recruiter-grade). No destructive cloud actions were run.

## Executive Summary
**Overall: PARTIAL** — the baseline is well-built and reproducible, but a couple evidence items need a quick re-capture after the latest Terraform hardening to make the repo “audit-tight”.

Top fixes (highest portfolio impact):
1. Re-capture the **logging S3 bucket policy** output after the latest Terraform hardening (`evidence/02-logging-before-after.md`).
2. Add/paste **Config archive bucket hardening** outputs (BPA/encryption/versioning/policy) to the detection/config evidence (`evidence/03-detection-findings.md` or a short addendum).
3. (Optional) Consider redacting account IDs / resource IDs if publishing publicly.

## Checklist (PASS / PARTIAL / FAIL)

| Item | Status | Notes |
|---|---|---|
| A) README quality + accuracy | PASS | Mermaid diagram renders and matches Terraform intent; strong “what/why/steps/links/cost” coverage. |
| B) Terraform correctness + hygiene | PASS | `terraform fmt -check -recursive`, `terraform init -backend=false`, `terraform validate` succeed; `.gitignore` blocks state/secrets; demo-only wildcard policy is gated. |
| C) Evidence quality (strict) | PARTIAL | Core evidence exists and has before/after for remediations, but logging bucket policy evidence is captured **pre-hardening**, and Config bucket hardening evidence isn’t pasted yet. |
| D) Security hardening sanity | PASS | Log/config buckets: BPA+encryption+versioning+HTTPS-only deny; bucket policies include confused-deputy protection patterns; bad IAM demo policy not created by default. |
| E) Scripts usability | PASS | Bash + PowerShell helpers exist; default behavior prints commands; execution requires explicit flags/switches. |

## Findings

### Documentation
- `runbooks/guardduty-triage.md:8` Runbook meets the required 1-page structure (trigger/triage/contain/investigate/remediate/prevent).
- `README.md` Links resolve; badges point to the configured GitHub remote; destroy guidance includes the `force_destroy_buckets` option.

### Evidence Quality (strict)
- `evidence/02-logging-before-after.md:46` The pasted `get-bucket-policy` output does **not** show the hardened policy currently in Terraform (it lacks `aws:SourceArn`, `aws:SourceAccount`, and `DenyInsecureTransport`). The file now calls out that it must be re-captured (`evidence/02-logging-before-after.md:53`), but until you paste the updated output this remains a strict PARTIAL.
- `evidence/03-detection-findings.md` Strong proof for GuardDuty + Security Hub + AWS Config + one control finding (EC2.18). Add/paste Config S3 bucket hardening outputs for completeness (BPA/encryption/versioning/policy) since README claims a hardened Config archive bucket.

### IaC Correctness
- `terraform/modules/config/main.tf:66` AWS Config S3 delivery policy now uses a safer/confident-deputy pattern (`aws:SourceAccount` + `ArnLike aws:SourceArn` prefix) rather than over-constraining to a single ARN.
- `terraform/modules/iam/main.tf` Demo wildcard policy is created only when `create_bad_policy_example=true` and is never attached by default.

### Security Hygiene
- No tracked Terraform state files (no `*.tfstate*` in `git ls-files`).
- No obvious credential strings found in tracked files (access keys, private keys, GitHub tokens).
- Public repo note: multiple evidence files include an AWS account ID and resource IDs; not secret, but consider redaction for privacy.

### Reproducibility
- GitHub Actions workflow runs safe checks (`.github/workflows/terraform.yml`).
- Evidence and remediation docs provide reproducible “simulate → verify-before → fix → verify-after → cleanup” blocks (`evidence/04-remediation-1-sg-open.md`, `evidence/05-remediation-2-s3-public.md`, `evidence/06-remediation-3-iam-wildcards.md`).

## Last-Mile Fixes (applied in this audit)

### Terraform: AWS Config S3 bucket policy condition hardening
File: `terraform/modules/config/main.tf`
- Switched `aws:SourceArn` condition to `ArnLike` with a region+account prefix (and kept `aws:SourceAccount`) to avoid over-constraining AWS Config deliveries.

### Docs: clarify “PASSED may be empty” and logging policy re-capture
Files:
- `evidence/03-detection-findings.md:447` re-labeled the post-remediation re-check as optional and clarified empty results.
- `evidence/02-logging-before-after.md:53` explicitly notes that the pasted bucket policy must be re-captured after the latest Terraform hardening.

## How To Verify (safe)

From repo root:
```powershell
cd terraform
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
```

Secret scan (safe):
```powershell
rg -n "AWS_ACCESS_KEY_ID|AWS_SECRET_ACCESS_KEY|AKIA[0-9A-Z]{16}|ASIA[0-9A-Z]{16}|BEGIN (RSA|OPENSSH) PRIVATE KEY|ghp_|github_pat_" -S .
```

## What To Capture Next (to convert PARTIAL → PASS)
1. Re-run and paste the *current* log bucket policy output into `evidence/02-logging-before-after.md`:
   - `aws s3api get-bucket-policy --bucket <LOG_BUCKET> --no-cli-pager`
   - `aws s3api get-bucket-ownership-controls --bucket <LOG_BUCKET> --no-cli-pager`
2. Paste Config archive bucket hardening evidence (BPA/encryption/versioning/policy) into `evidence/03-detection-findings.md`:
   - `aws s3api get-public-access-block --bucket <CONFIG_BUCKET> --no-cli-pager`
   - `aws s3api get-bucket-encryption --bucket <CONFIG_BUCKET> --no-cli-pager`
   - `aws s3api get-bucket-versioning --bucket <CONFIG_BUCKET> --no-cli-pager`
   - `aws s3api get-bucket-policy --bucket <CONFIG_BUCKET> --no-cli-pager`
