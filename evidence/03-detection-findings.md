# Detection Baseline - Evidence (GuardDuty + Security Hub)

## Goal
Prove that:
- GuardDuty is enabled and generating findings
- Security Hub is enabled with a security standard
- A safe simulation can produce a finding, and the finding can be remediated

## GuardDuty enabled
`aws guardduty list-detectors --no-cli-pager`
```json
{
    "DetectorIds": [
        "c2db5b53828d466d95f96fc901f93832"
    ]
}
```

`aws guardduty get-detector --detector-id c2db5b53828d466d95f96fc901f93832 --no-cli-pager`
```json
{
    "CreatedAt": "2025-12-21T01:06:24.915Z",
    "FindingPublishingFrequency": "SIX_HOURS",
    "ServiceRole": "arn:aws:iam::176087999560:role/aws-service-role/guardduty.amazonaws.com/AWSServiceRoleForAmazonGuardDuty",
    "Status": "ENABLED",
    "UpdatedAt": "2025-12-21T01:06:24.915Z",
    "DataSources": {
        "CloudTrail": {
            "Status": "ENABLED"
        },
        "DNSLogs": {
            "Status": "ENABLED"
        },
        "FlowLogs": {
            "Status": "ENABLED"
        },
        "S3Logs": {
            "Status": "ENABLED"
        },
        "Kubernetes": {
            "AuditLogs": {
                "Status": "ENABLED"
            }
        },
        "MalwareProtection": {
            "ScanEc2InstanceWithFindings": {
                "EbsVolumes": {
                    "Status": "ENABLED"
                }
            },
            "ServiceRole": "arn:aws:iam::176087999560:role/aws-service-role/malware-protection.guardduty.amazonaws.com/AWSServiceRoleForAmazonGuardDutyMalwareProtection"
        }
    },
    "Tags": {
        "Env": "dev",
        "Project": "aws-cloud-security-baseline",
        "Owner": "emerson"
    },
    "Features": [
        {
            "Name": "CLOUD_TRAIL",
            "Status": "ENABLED",
            "UpdatedAt": "2025-12-20T18:06:56-07:00"
        },
        {
            "Name": "DNS_LOGS",
            "Status": "ENABLED",
            "UpdatedAt": "2025-12-20T18:06:56-07:00"
        },
        {
            "Name": "FLOW_LOGS",
            "Status": "ENABLED",
            "UpdatedAt": "2025-12-20T18:06:56-07:00"
        },
        {
            "Name": "S3_DATA_EVENTS",
            "Status": "ENABLED",
            "UpdatedAt": "2025-12-20T18:06:24-07:00"
        },
        {
            "Name": "EKS_AUDIT_LOGS",
            "Status": "ENABLED",
            "UpdatedAt": "2025-12-20T18:06:24-07:00"
        },
        {
            "Name": "EBS_MALWARE_PROTECTION",
            "Status": "ENABLED",
            "UpdatedAt": "2025-12-20T18:06:24-07:00"
        },
        {
            "Name": "RDS_LOGIN_EVENTS",
            "Status": "ENABLED",
            "UpdatedAt": "2025-12-20T18:06:25-07:00"
        },
        {
            "Name": "EKS_RUNTIME_MONITORING",
            "Status": "DISABLED",
            "UpdatedAt": "2025-12-20T18:06:25-07:00",
            "AdditionalConfiguration": [
                {
                    "Name": "EKS_ADDON_MANAGEMENT",
                    "Status": "DISABLED",
                    "UpdatedAt": "2025-12-20T18:06:25-07:00"
                }
            ]
        },
        {
            "Name": "LAMBDA_NETWORK_LOGS",
            "Status": "ENABLED",
            "UpdatedAt": "2025-12-20T18:06:25-07:00"
        },
        {
            "Name": "RUNTIME_MONITORING",
            "Status": "DISABLED",
            "UpdatedAt": "2025-12-20T18:06:25-07:00",
            "AdditionalConfiguration": [
                {
                    "Name": "EKS_ADDON_MANAGEMENT",
                    "Status": "DISABLED",
                    "UpdatedAt": "2025-12-20T18:06:25-07:00"
                },
                {
                    "Name": "ECS_FARGATE_AGENT_MANAGEMENT",
                    "Status": "DISABLED",
                    "UpdatedAt": "2025-12-20T18:06:25-07:00"
                },
                {
                    "Name": "EC2_AGENT_MANAGEMENT",
                    "Status": "DISABLED",
                    "UpdatedAt": "2025-12-20T18:06:25-07:00"
                }
            ]
        }
    ]
}
```

## Security Hub enabled + standards
`aws securityhub describe-hub --no-cli-pager`
```json
{
    "HubArn": "arn:aws:securityhub:us-east-1:176087999560:hub/default",
    "SubscribedAt": "2025-12-21T01:06:24.768Z",
    "AutoEnableControls": true,
    "ControlFindingGenerator": "SECURITY_CONTROL"
}
```

`aws securityhub get-enabled-standards --no-cli-pager`
```json
{
    "StandardsSubscriptions": [
        {
            "StandardsSubscriptionArn": "arn:aws:securityhub:us-east-1:176087999560:subscription/cis-aws-foundations-benchmark/v/1.2.0",
            "StandardsArn": "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0",
            "StandardsInput": {},
            "StandardsStatus": "INCOMPLETE",
            "StandardsControlsUpdatable": "READY_FOR_UPDATES",
            "StandardsStatusReason": {
                "StatusReasonCode": "NO_AVAILABLE_CONFIGURATION_RECORDER"
            }
        },
        {
            "StandardsSubscriptionArn": "arn:aws:securityhub:us-east-1:176087999560:subscription/aws-foundational-security-best-practices/v/1.0.0",
            "StandardsArn": "arn:aws:securityhub:us-east-1::standards/aws-foundational-security-best-practices/v/1.0.0",
            "StandardsInput": {},
            "StandardsStatus": "INCOMPLETE",
            "StandardsControlsUpdatable": "READY_FOR_UPDATES",
            "StandardsStatusReason": {
                "StatusReasonCode": "NO_AVAILABLE_CONFIGURATION_RECORDER"
            }
        }
    ]
}
```

## Safe finding demo
### Simulation: open SSH to the world on a temporary security group
`aws ec2 describe-security-groups --group-ids sg-0422a2fc3e197ae2f --no-cli-pager`
```json
{
    "SecurityGroups": [
        {
            "GroupId": "sg-0422a2fc3e197ae2f",
            "IpPermissionsEgress": [
                {
                    "IpProtocol": "-1",
                    "UserIdGroupPairs": [],
                    "IpRanges": [
                        {
                            "CidrIp": "0.0.0.0/0"
                        }
                    ],
                    "Ipv6Ranges": [],
                    "PrefixListIds": []
                }
            ],
            "VpcId": "vpc-035de9c63c12c4cc2",
            "SecurityGroupArn": "arn:aws:ec2:us-east-1:176087999560:security-group/sg-0422a2fc3e197ae2f",
            "OwnerId": "176087999560",
            "GroupName": "acs-baseline-demo-open-ssh",
            "Description": "Demo misconfig to generate Security Hub finding (temporary)",
            "IpPermissions": [
                {
                    "IpProtocol": "tcp",
                    "FromPort": 22,
                    "ToPort": 22,
                    "UserIdGroupPairs": [],
                    "IpRanges": [
                        {
                            "CidrIp": "0.0.0.0/0"
                        }
                    ],
                    "Ipv6Ranges": [],
                    "PrefixListIds": []
                }
            ]
        }
    ]
}
```

`aws securityhub get-findings --filters <ResourceId filter> --no-cli-pager`
```json
{
    "Findings": []
}
```

### Remediation (remove open ingress)
`aws ec2 describe-security-groups --group-ids sg-0422a2fc3e197ae2f --no-cli-pager`
```json
{
    "SecurityGroups": [
        {
            "GroupId": "sg-0422a2fc3e197ae2f",
            "IpPermissionsEgress": [
                {
                    "IpProtocol": "-1",
                    "UserIdGroupPairs": [],
                    "IpRanges": [
                        {
                            "CidrIp": "0.0.0.0/0"
                        }
                    ],
                    "Ipv6Ranges": [],
                    "PrefixListIds": []
                }
            ],
            "VpcId": "vpc-035de9c63c12c4cc2",
            "SecurityGroupArn": "arn:aws:ec2:us-east-1:176087999560:security-group/sg-0422a2fc3e197ae2f",
            "OwnerId": "176087999560",
            "GroupName": "acs-baseline-demo-open-ssh",
            "Description": "Demo misconfig to generate Security Hub finding (temporary)",
            "IpPermissions": []
        }
    ]
}
```

## Notes
- Security Hub standards show NO_AVAILABLE_CONFIGURATION_RECORDER, so control findings may not be generated until AWS Config is enabled.
- The demo security group was deleted after remediation.
