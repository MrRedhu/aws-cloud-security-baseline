# IAM Least Privilege - Before/After Evidence

## Goal
Demonstrate least-privilege IAM design for three personas and show an explicit bad policy -> fixed policy improvement with verifiable evidence.

## Personas implemented (roles)
- **Admin**: baseline full admin capabilities for controlled management operations (role: `acs-baseline-admin-role`)
- **Developer**: limited permissions required for day-to-day visibility and troubleshooting (role: `acs-baseline-developer-role`)
- **Read-only**: environment visibility without mutation permissions (role: `acs-baseline-readonly-role`)

## Identity confirmation
`aws sts get-caller-identity`
```json
{
    "UserId": "176087999560",
    "Account": "176087999560",
    "Arn": "arn:aws:iam::176087999560:root"
}
```

## BEFORE (intentionally bad policy example)
This repo includes an intentionally unsafe policy to demonstrate what overly permissive IAM looks like:
- Policy: `acs-baseline-dev-bad-wildcard`
- Risk: Allows `Action="*"` on `Resource="*"` which effectively grants full account control if attached to a role/user.

**Important (baseline default):** The bad policy is a **demo-only artifact**. It is **not attached** in the baseline by default, and it is created only when Terraform is run with `create_bad_policy_example=true`. The attach/detach remediation (before → after) is demonstrated in `evidence/06-remediation-3-iam-wildcards.md`.

### Evidence (bad policy JSON)
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
Developer permissions are enforced via a least-privilege policy attached to the Developer role:
- Baseline default attaches the fixed policy (no wildcard admin-like access)
- Adds scoped read/describe permissions needed for security visibility
- Adds explicit deny for IAM / org / account write actions to prevent privilege escalation

## AFTER (least privilege policy attached to Developer role)
Developer role now has the fixed policy attached:
- Policy: `acs-baseline-dev-fixed`

### Attachment proof
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

### Evidence (fixed policy JSON)
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

## Role existence (optional)
`aws iam get-role --role-name acs-baseline-admin-role`
```json
{
    "Role": {
        "Path": "/",
        "RoleName": "acs-baseline-admin-role",
        "RoleId": "AROASR75JUREFAXYJ2FMG",
        "Arn": "arn:aws:iam::176087999560:role/acs-baseline-admin-role",
        "CreateDate": "2025-12-21T00:22:44+00:00",
        "AssumeRolePolicyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {
                        "AWS": "arn:aws:iam::176087999560:root"
                    },
                    "Action": "sts:AssumeRole"
                }
            ]
        },
        "MaxSessionDuration": 3600,
        "Tags": [
            {
                "Key": "Project",
                "Value": "aws-cloud-security-baseline"
            },
            {
                "Key": "Env",
                "Value": "dev"
            },
            {
                "Key": "Owner",
                "Value": "emerson"
            }
        ],
        "RoleLastUsed": {}
    }
}
```

`aws iam get-role --role-name acs-baseline-developer-role`
```json
{
    "Role": {
        "Path": "/",
        "RoleName": "acs-baseline-developer-role",
        "RoleId": "AROASR75JURECDSUF344Y",
        "Arn": "arn:aws:iam::176087999560:role/acs-baseline-developer-role",
        "CreateDate": "2025-12-21T00:22:44+00:00",
        "AssumeRolePolicyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {
                        "AWS": "arn:aws:iam::176087999560:root"
                    },
                    "Action": "sts:AssumeRole"
                }
            ]
        },
        "MaxSessionDuration": 3600,
        "Tags": [
            {
                "Key": "Owner",
                "Value": "emerson"
            },
            {
                "Key": "Project",
                "Value": "aws-cloud-security-baseline"
            },
            {
                "Key": "Env",
                "Value": "dev"
            }
        ],
        "RoleLastUsed": {}
    }
}
```

`aws iam get-role --role-name acs-baseline-readonly-role`
```json
{
    "Role": {
        "Path": "/",
        "RoleName": "acs-baseline-readonly-role",
        "RoleId": "AROASR75JURECR4JBZ7PN",
        "Arn": "arn:aws:iam::176087999560:role/acs-baseline-readonly-role",
        "CreateDate": "2025-12-21T00:22:44+00:00",
        "AssumeRolePolicyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {
                        "AWS": "arn:aws:iam::176087999560:root"
                    },
                    "Action": "sts:AssumeRole"
                }
            ]
        },
        "MaxSessionDuration": 3600,
        "Tags": [
            {
                "Key": "Env",
                "Value": "dev"
            },
            {
                "Key": "Owner",
                "Value": "emerson"
            },
            {
                "Key": "Project",
                "Value": "aws-cloud-security-baseline"
            }
        ],
        "RoleLastUsed": {}
    }
}
```

## Notes (tightening later)
At this stage, some statements still use `Resource="*"` for read-only discovery actions. Once logging resources exist (S3 log bucket, specific CloudWatch log groups), this policy will be tightened further to target specific ARNs instead of wildcard resources.
