# Detection Baseline - Evidence (GuardDuty + Security Hub)

## Goal
Prove that:
- GuardDuty is enabled and generating findings
- Security Hub is enabled with a security standard
- AWS Config is enabled (required for Security Hub controls)
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
            "UpdatedAt": "2025-12-20T19:13:37-07:00"
        },
        {
            "Name": "DNS_LOGS",
            "Status": "ENABLED",
            "UpdatedAt": "2025-12-20T19:13:37-07:00"
        },
        {
            "Name": "FLOW_LOGS",
            "Status": "ENABLED",
            "UpdatedAt": "2025-12-20T19:13:37-07:00"
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
            "StandardsSubscriptionArn": "arn:aws:securityhub:us-east-1:176087999560:subscription/aws-foundational-security-best-practices/v/1.0.0",
            "StandardsArn": "arn:aws:securityhub:us-east-1::standards/aws-foundational-security-best-practices/v/1.0.0",
            "StandardsInput": {},
            "StandardsStatus": "READY",
            "StandardsControlsUpdatable": "READY_FOR_UPDATES"
        }
    ]
}
```

## AWS Config enabled (required for Security Hub controls)
`aws configservice describe-configuration-recorder-status --no-cli-pager`
```json
{
    "ConfigurationRecordersStatus": [
        {
            "arn": "arn:aws:config:us-east-1:176087999560:configuration-recorder/acs-baseline-config-recorder/dl43uq2gcapx3jk7",
            "name": "acs-baseline-config-recorder",
            "lastStartTime": "2025-12-20T18:34:43.405000-07:00",
            "recording": true,
            "lastStatus": "SUCCESS",
            "lastStatusChangeTime": "2025-12-20T18:34:53.787000-07:00"
        }
    ]
}
```

`aws configservice describe-configuration-recorders --no-cli-pager`
```json
{
    "ConfigurationRecorders": [
        {
            "arn": "arn:aws:config:us-east-1:176087999560:configuration-recorder/acs-baseline-config-recorder/dl43uq2gcapx3jk7",
            "name": "acs-baseline-config-recorder",
            "roleARN": "arn:aws:iam::176087999560:role/aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig",
            "recordingGroup": {
                "allSupported": true,
                "includeGlobalResourceTypes": true,
                "resourceTypes": [],
                "exclusionByResourceTypes": {
                    "resourceTypes": []
                },
                "recordingStrategy": {
                    "useOnly": "ALL_SUPPORTED_RESOURCE_TYPES"
                }
            },
            "recordingMode": {
                "recordingFrequency": "CONTINUOUS",
                "recordingModeOverrides": []
            },
            "recordingScope": "PAID"
        }
    ]
}
```

`aws configservice describe-delivery-channels --no-cli-pager`
```json
{
    "DeliveryChannels": [
        {
            "name": "acs-baseline-config-delivery",
            "s3BucketName": "acs-baseline-176087999560-config-archive"
        }
    ]
}
```

`aws securityhub get-enabled-standards --query "StandardsSubscriptions[].{Arn:StandardsArn,Status:StandardsStatus,Reason:StandardsStatusReason.StatusReasonCode}" --output table --no-cli-pager`
```
---------------------------------------------------------------------------------------------------------
|                                          GetEnabledStandards                                          |
+--------+----------------------------------------------------------------------------------------------+
|  Arn   |  arn:aws:securityhub:us-east-1::standards/aws-foundational-security-best-practices/v/1.0.0   |
|  Reason|  None                                                                                        |
|  Status|  READY                                                                                       |
+--------+----------------------------------------------------------------------------------------------+
```

## Safe finding demo (open SSH)
### Simulation: open SSH to the world on a temporary security group
`aws ec2 describe-security-groups --group-ids sg-02b31fdeef63dde30 --no-cli-pager`
```json
{
    "SecurityGroups": [
        {
            "GroupId": "sg-02b31fdeef63dde30",
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
            "SecurityGroupArn": "arn:aws:ec2:us-east-1:176087999560:security-group/sg-02b31fdeef63dde30",
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

`aws securityhub get-findings --filters <ResourceId + ComplianceStatus FAILED> --no-cli-pager`
```json
{
    "Findings": [
        {
            "SchemaVersion": "2018-10-08",
            "Id": "arn:aws:securityhub:us-east-1:176087999560:security-control/EC2.18/finding/7c102ee7-d71a-4eef-b850-9f3d9bbccb32",
            "ProductArn": "arn:aws:securityhub:us-east-1::product/aws/securityhub",
            "ProductName": "Security Hub",
            "CompanyName": "AWS",
            "Region": "us-east-1",
            "GeneratorId": "security-control/EC2.18",
            "AwsAccountId": "176087999560",
            "Types": [
                "Software and Configuration Checks/Industry and Regulatory Standards"
            ],
            "FirstObservedAt": "2025-12-21T02:14:54.242Z",
            "LastObservedAt": "2025-12-21T02:14:54.242Z",
            "CreatedAt": "2025-12-21T02:15:28.917Z",
            "UpdatedAt": "2025-12-21T02:15:28.917Z",
            "Severity": {
                "Label": "HIGH",
                "Normalized": 70,
                "Original": "HIGH"
            },
            "Title": "Security groups should only allow unrestricted incoming traffic for authorized ports",
            "Description": "This control checks whether an Amazon EC2 security group permits unrestricted incoming traffic from unauthorized ports. The control status is determined as follows: If you use the default value for 'authorizedTcpPorts', the control fails if the security group permits unrestricted incoming traffic from any port other than ports 80 and 443; If you provide custom values for 'authorizedTcpPorts' or 'authorizedUdpPorts', the control fails if the security group permits unrestricted incoming traffic from any unlisted port; If no parameter is used, the control fails for any security group that has an unrestricted inbound traffic rule.",
            "Remediation": {
                "Recommendation": {
                    "Text": "For information on how to correct this issue, consult the AWS Security Hub controls documentation.",
                    "Url": "https://docs.aws.amazon.com/console/securityhub/EC2.18/remediation"
                }
            },
            "ProductFields": {
                "RelatedAWSResources:0/name": "securityhub-vpc-sg-open-only-to-authorized-ports-20a6a216",
                "RelatedAWSResources:0/type": "AWS::Config::ConfigRule",
                "aws/securityhub/ProductName": "Security Hub",
                "aws/securityhub/CompanyName": "AWS",
                "aws/securityhub/annotation": "No tcp ['22'] port is authorized to be open, according to authorizedTcpPorts values ['80,443'] parameter.",
                "Resources:0/Id": "arn:aws:ec2:us-east-1:176087999560:security-group/sg-02b31fdeef63dde30",
                "aws/securityhub/FindingId": "arn:aws:securityhub:us-east-1::product/aws/securityhub/arn:aws:securityhub:us-east-1:176087999560:security-control/EC2.18/finding/7c102ee7-d71a-4eef-b850-9f3d9bbccb32"
            },
            "Resources": [
                {
                    "Type": "AwsEc2SecurityGroup",
                    "Id": "arn:aws:ec2:us-east-1:176087999560:security-group/sg-02b31fdeef63dde30",
                    "Partition": "aws",
                    "Region": "us-east-1",
                    "Details": {
                        "AwsEc2SecurityGroup": {
                            "GroupName": "acs-baseline-demo-open-ssh",
                            "GroupId": "sg-02b31fdeef63dde30",
                            "OwnerId": "176087999560",
                            "VpcId": "vpc-035de9c63c12c4cc2",
                            "IpPermissions": [
                                {
                                    "IpProtocol": "tcp",
                                    "FromPort": 22,
                                    "ToPort": 22,
                                    "IpRanges": [
                                        {
                                            "CidrIp": "0.0.0.0/0"
                                        }
                                    ]
                                }
                            ],
                            "IpPermissionsEgress": [
                                {
                                    "IpProtocol": "-1",
                                    "IpRanges": [
                                        {
                                            "CidrIp": "0.0.0.0/0"
                                        }
                                    ]
                                }
                            ]
                        }
                    }
                }
            ],
            "Compliance": {
                "Status": "FAILED",
                "SecurityControlId": "EC2.18",
                "AssociatedStandards": [
                    {
                        "StandardsId": "standards/aws-foundational-security-best-practices/v/1.0.0"
                    }
                ],
                "SecurityControlParameters": [
                    {
                        "Name": "authorizedUdpPorts",
                        "Value": []
                    },
                    {
                        "Name": "authorizedTcpPorts",
                        "Value": [
                            "80",
                            "443"
                        ]
                    }
                ]
            },
            "WorkflowState": "NEW",
            "Workflow": {
                "Status": "NEW"
            },
            "RecordState": "ACTIVE",
            "FindingProviderFields": {
                "Severity": {
                    "Label": "HIGH",
                    "Original": "HIGH"
                },
                "Types": [
                    "Software and Configuration Checks/Industry and Regulatory Standards"
                ]
            },
            "ProcessedAt": "2025-12-21T02:15:33.885Z"
        }
    ]
}
```

### Remediation (remove open ingress)
`aws ec2 describe-security-groups --group-ids sg-02b31fdeef63dde30 --no-cli-pager`
```json
{
    "SecurityGroups": [
        {
            "GroupId": "sg-02b31fdeef63dde30",
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
            "SecurityGroupArn": "arn:aws:ec2:us-east-1:176087999560:security-group/sg-02b31fdeef63dde30",
            "OwnerId": "176087999560",
            "GroupName": "acs-baseline-demo-open-ssh",
            "Description": "Demo misconfig to generate Security Hub finding (temporary)",
            "IpPermissions": []
        }
    ]
}
```

### Deletion proof (demo SG removed)
`aws ec2 describe-security-groups --group-ids sg-02b31fdeef63dde30 --no-cli-pager`
```
An error occurred (InvalidGroup.NotFound) when calling the DescribeSecurityGroups operation: The security group 'sg-02b31fdeef63dde30' does not exist
```

### Post-remediation control status (PASSED)
`aws securityhub get-findings --filters <ResourceId + ComplianceStatus PASSED> --no-cli-pager`
```json
{
    "Findings": []
}
```

## GuardDuty sample findings (Security Hub ingestion check)
`aws guardduty create-sample-findings --detector-id c2db5b53828d466d95f96fc901f93832 --no-cli-pager`

`aws securityhub get-findings --filters <ProductName GuardDuty> --no-cli-pager`
```json
[
    {
        "Id": "arn:aws:guardduty:us-east-1:176087999560:detector/c2db5b53828d466d95f96fc901f93832/finding/de030c3042f7478990890903bcf22039",
        "Title": "A container has mounted a host directory.",
        "Severity": "MEDIUM",
        "ProductName": "GuardDuty",
        "Types": [
            "TTPs/Privilege Escalation/PrivilegeEscalation:Runtime-ContainerMountsHostDirectory"
        ],
        "Sample": true,
        "Resources": [
            {
                "Type": "AwsEc2Instance",
                "Id": "arn:aws:ec2:us-east-1:176087999560:instance/i-99999999",
                "Partition": "aws",
                "Region": "us-east-1",
                "Tags": {
                    "GeneratedFindingInstanceTag1": "GeneratedFindingInstanceValue1",
                    "GeneratedFindingInstanceTag2": "GeneratedFindingInstanceTagValue2",
                    "GeneratedFindingInstanceTag3": "GeneratedFindingInstanceTagValue3",
                    "GeneratedFindingInstanceTag4": "GeneratedFindingInstanceTagValue4",
                    "GeneratedFindingInstanceTag5": "GeneratedFindingInstanceTagValue5",
                    "GeneratedFindingInstanceTag6": "GeneratedFindingInstanceTagValue6",
                    "GeneratedFindingInstanceTag7": "GeneratedFindingInstanceTagValue7",
                    "GeneratedFindingInstanceTag8": "GeneratedFindingInstanceTagValue8",
                    "GeneratedFindingInstanceTag9": "GeneratedFindingInstanceTagValue9"
                },
                "Details": {
                    "AwsEc2Instance": {
                        "Type": "m3.xlarge",
                        "ImageId": "ami-99999999",
                        "IpV4Addresses": [
                            "10.0.0.1",
                            "198.51.100.0"
                        ],
                        "IamInstanceProfileArn": "arn:aws:iam::012345678999:instance-profile/generated",
                        "VpcId": "vpc-generatedvpcid",
                        "SubnetId": "GeneratedFindingSubnetId",
                        "LaunchedAt": "2016-08-02T02:05:06.000Z"
                    }
                }
            }
        ]
    }
]
```

## Notes
- Security Hub standards are READY after AWS Config is enabled.
- The demo security group was deleted after remediation.
