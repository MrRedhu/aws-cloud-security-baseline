# Remediation 3 - IAM overly permissive wildcard policy

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

## Prevention
- Require review + CI checks (policy linting)
- Deny IAM writes for developer personas (already included)
- Use permission boundaries / SCPs in org environments (future)
