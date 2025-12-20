# Environment & Guardrails

## Purpose
This document records the environment details needed to reproduce the baseline and verify evidence.

## Environment
- Date created:
- AWS Region:
- Account type: (sandbox / dedicated / separate account)
- Provisioning method: (Terraform / AWS CLI)
- Repo commit for first deployment:

## Cost & Safety Guardrails
- AWS Budget alert configured: (yes/no, threshold)
- Tagging convention used:
  - Project=aws-cloud-security-baseline
  - Owner=
  - Env=dev

## Notes (important)
- Do not commit secrets (AWS keys, session tokens, private logs).
- All "risky behavior" is simulated via safe misconfigurations only (no exploitation).
