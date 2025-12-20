# GuardDuty Triage Runbook (Template)

## Trigger
- Example finding type:
- Severity:
- Affected account/region:

## Triage (first 5-10 minutes)
- Confirm finding is real (not test/noise)
- Identify impacted principal (user/role), resource, and timeframe
- Check for related findings / unusual spikes

## Containment (first 15-30 minutes)
- Revoke/rotate credentials (if user or access keys)
- Restrict network exposure (security groups / NACLs)
- Isolate compute if needed (stop instance, detach from network, snapshot)

## Investigation
- CloudTrail lookups (who did what, when)
- CloudWatch Logs / VPC Flow Logs for supporting signals
- Identify blast radius (what else this principal can access)

## Remediation (fix root cause)
- Tighten IAM policy / remove wildcards
- Fix misconfig (S3 public access, SG open ingress, etc.)
- Patch/rotate affected components

## Prevention
- Add guardrails (policy-as-code checks, Security Hub monitoring)
- Update baseline modules to prevent recurrence
