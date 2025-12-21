# GuardDuty Triage Runbook

## Trigger
- Example finding: `UnauthorizedAccess:IAMUser/ConsoleLogin` or Security Hub control `EC2.18` (open SSH)
- Severity: Low/Medium/High
- Account/Region: us-east-1 (or affected region)

## Triage (first 5–10 minutes)
- Confirm the finding is not a sample/test and is still active
- Identify impacted principal (user/role), resource, and timeframe
- Check for correlated findings (same principal, IP, or resource)
- Determine if data exfil or privilege escalation is possible

## Containment (first 15–30 minutes)
- Revoke or rotate credentials for impacted principal (access keys, sessions)
- Restrict network exposure (tighten SG/NACL, block suspicious IPs)
- Isolate affected compute if needed (stop instance, detach ENI, snapshot)

## Investigation
- CloudTrail: who did what, when, from where (source IP, user agent)
- GuardDuty finding details: evidence, action type, affected resources
- CloudWatch Logs and VPC Flow Logs for supporting signals
- Identify blast radius: policies, attached roles, reachable resources

## Remediation (fix root cause)
- Remove overly permissive IAM policies and wildcards
- Repair misconfigurations (S3 public access, SG open ingress, etc.)
- Patch or rotate affected components (keys, tokens, instances)

## Prevention
- Add guardrails: SCPs/permission boundaries, policy-as-code checks
- Enable/verify Security Hub controls and alerting
- Update Terraform baseline modules to enforce safe defaults
