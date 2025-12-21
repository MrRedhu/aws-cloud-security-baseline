# Remediation 3 - IAM overly permissive wildcard policy

## Reproduce (safe demo)
This demo attaches an intentionally bad wildcard policy to a temporary role, then remediates by replacing it with the baseline least-privilege policy and deleting the role.

### 1) Simulate misconfiguration (attach wildcard policy to demo role)
```powershell
$env:AWS_PAGER=""

cd terraform
$FIXED_POLICY_ARN = terraform output -raw fixed_policy_arn
$BAD_POLICY_ARN = terraform output -raw bad_policy_arn
cd ..

# If bad_policy_arn is empty/null, enable the demo-only policy and apply:
#   cd terraform
#   terraform apply -var="create_bad_policy_example=true"
#   terraform output -raw bad_policy_arn

$ROLE="acs-baseline-demo-bad-iam-$((Get-Date).ToString('yyyyMMddHHmmss'))"

$ACCOUNT_ID = aws sts get-caller-identity --query Account --output text --no-cli-pager

@"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "AWS": "arn:aws:iam::$ACCOUNT_ID:root" },
      "Action": "sts:AssumeRole"
    }
  ]
}
"@ | Out-File -Encoding ascii -FilePath .\\trust-demo-role.json

aws iam create-role `
  --role-name $ROLE `
  --assume-role-policy-document file://trust-demo-role.json `
  --no-cli-pager

aws iam attach-role-policy --role-name $ROLE --policy-arn $BAD_POLICY_ARN --no-cli-pager
```

### 2) Verify-before (proof)
```powershell
aws iam list-attached-role-policies --role-name $ROLE --no-cli-pager
aws iam get-policy-version --policy-arn $BAD_POLICY_ARN --version-id v1 --no-cli-pager
```

### 3) Fix (replace wildcard with least-privilege policy)
```powershell
aws iam detach-role-policy --role-name $ROLE --policy-arn $BAD_POLICY_ARN --no-cli-pager
aws iam attach-role-policy --role-name $ROLE --policy-arn $FIXED_POLICY_ARN --no-cli-pager
```

### 4) Verify-after (proof) + cleanup
```powershell
aws iam list-attached-role-policies --role-name $ROLE --no-cli-pager
aws iam get-policy-version --policy-arn $FIXED_POLICY_ARN --version-id v1 --no-cli-pager

aws iam detach-role-policy --role-name $ROLE --policy-arn $FIXED_POLICY_ARN --no-cli-pager
aws iam delete-role --role-name $ROLE --no-cli-pager
aws iam get-role --role-name $ROLE --no-cli-pager
```

## Issue
Wildcard IAM permissions (Action="*" / Resource="*") create privilege escalation risk and violate least privilege.

## Detection signal (expected)
- Security Hub IAM control(s) and/or policy review evidence
- Compliance: FAILED (or documented risk if control is not surfaced)

## BEFORE evidence
`aws iam list-attached-role-policies --role-name acs-baseline-demo-bad-iam --no-cli-pager`
```json
{
    "AttachedPolicies": [
        {
            "PolicyName": "acs-baseline-dev-bad-wildcard",
            "PolicyArn": "arn:aws:iam::176087999560:policy/acs-baseline-dev-bad-wildcard"
        }
    ]
}
```

`aws iam get-policy-version --policy-arn arn:aws:iam::176087999560:policy/acs-baseline-dev-bad-wildcard --version-id v1 --no-cli-pager`
```json
{
    "PolicyVersion": {
        "Document": {
            "Statement": [
                {
                    "Action": "*",
                    "Effect": "Allow",
                    "Resource": "*",
                    "Sid": "BadWildcard"
                }
            ],
            "Version": "2012-10-17"
        },
        "VersionId": "v1",
        "IsDefaultVersion": true,
        "CreateDate": "2025-12-21T00:22:44+00:00"
    }
}
```

## Remediation
Detach the wildcard policy and attach the least-privilege policy.

## Change (diff)
- Attached policy: acs-baseline-dev-bad-wildcard
+ Attached policy: acs-baseline-dev-fixed

## AFTER evidence
`aws iam list-attached-role-policies --role-name acs-baseline-demo-bad-iam --no-cli-pager`
```json
{
    "AttachedPolicies": [
        {
            "PolicyName": "acs-baseline-dev-fixed",
            "PolicyArn": "arn:aws:iam::176087999560:policy/acs-baseline-dev-fixed"
        }
    ]
}
```

`aws iam get-policy-version --policy-arn arn:aws:iam::176087999560:policy/acs-baseline-dev-fixed --version-id v1 --no-cli-pager`
```json
{
    "PolicyVersion": {
        "Document": {
            "Statement": [
                {
                    "Action": [
                        "ec2:Describe*",
                        "s3:ListAllMyBuckets",
                        "cloudtrail:Describe*",
                        "cloudtrail:Get*",
                        "guardduty:List*",
                        "guardduty:Get*",
                        "securityhub:Get*",
                        "securityhub:Describe*",
                        "securityhub:List*"
                    ],
                    "Effect": "Allow",
                    "Resource": "*",
                    "Sid": "AllowDescribeList"
                },
                {
                    "Action": [
                        "logs:Describe*",
                        "logs:Get*",
                        "logs:FilterLogEvents",
                        "logs:StartQuery",
                        "logs:GetQueryResults"
                    ],
                    "Effect": "Allow",
                    "Resource": "*",
                    "Sid": "AllowCloudWatchLogsRead"
                },
                {
                    "Action": [
                        "iam:*",
                        "organizations:*",
                        "account:*"
                    ],
                    "Effect": "Deny",
                    "Resource": "*",
                    "Sid": "DenyIAMWrites"
                }
            ],
            "Version": "2012-10-17"
        },
        "VersionId": "v1",
        "IsDefaultVersion": true,
        "CreateDate": "2025-12-21T00:22:44+00:00"
    }
}
```

## Cleanup proof
`aws iam get-role --role-name acs-baseline-demo-bad-iam --no-cli-pager`
```
An error occurred (NoSuchEntity) when calling the GetRole operation: The role with name acs-baseline-demo-bad-iam cannot be found.
```

## Cleanup recheck
`aws iam get-role --role-name acs-baseline-demo-bad-iam --no-cli-pager`
```
An error occurred (NoSuchEntity) when calling the GetRole operation: The role with name acs-baseline-demo-bad-iam cannot be found.
```

## Prevention
- Require review + CI checks (policy linting)
- Deny IAM writes for developer personas (already included)
- Use permission boundaries / SCPs in org environments (future)
