# IAM Least Privilege - Before/After Evidence

## Goal
Demonstrate least-privilege IAM design for three personas and show an explicit bad policy -> fixed policy remediation with proof.

## Personas implemented
- Admin: full access (baseline admin role)
- Developer: limited access (will be tightened further as resource ARNs exist)
- Read-only: AWS managed read-only baseline

## BEFORE (intentionally bad)
**What was wrong:** Developer role had an attached policy that allowed `Action="*"` and `Resource="*"`.

### Evidence to paste
Paste:
- `aws iam list-attached-role-policies --role-name <developer-role>`
- `aws iam get-policy-version --policy-arn <bad-policy-arn> --version-id v1`

### Collected output
`aws sts get-caller-identity`
```json
{
    "UserId": "176087999560",
    "Account": "176087999560",
    "Arn": "arn:aws:iam::176087999560:root"
}
```

`aws iam list-attached-role-policies --role-name acs-baseline-developer-role`
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

`aws iam get-policy-version --policy-arn arn:aws:iam::176087999560:policy/acs-baseline-dev-bad-wildcard --version-id v1`
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

## CHANGE
Replace the attached developer policy from bad wildcard to fixed least privilege.

### Evidence to paste
Paste:
- Terraform diff showing the attachment change (optional)
- `aws iam list-attached-role-policies --role-name <developer-role>`

## AFTER (least privilege)
**What is improved:** Wildcard access removed; developer role is restricted to specific read/describe actions and explicitly denied IAM/org/account write actions.

### Evidence to paste
Paste:
- `aws iam get-policy-version --policy-arn <fixed-policy-arn> --version-id v1`
- `aws iam list-attached-role-policies --role-name <developer-role>`

### Collected output
`aws iam list-attached-role-policies --role-name acs-baseline-developer-role`
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

`aws iam get-policy-version --policy-arn arn:aws:iam::176087999560:policy/acs-baseline-dev-fixed --version-id v1`
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

## Notes
Once logging resources exist (CloudWatch log groups, S3 log bucket), this policy will be tightened to specific ARNs instead of `Resource="*"`.
