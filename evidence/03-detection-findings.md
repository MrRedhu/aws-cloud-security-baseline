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
----------------------------------------------------------------------------------------------------------------------------------------------------
|                                                                GetEnabledStandards                                                               |
+--------------------------------------------------------------------------------------------+---------------------------------------+-------------+
|                                             Arn                                            |                Reason                 |   Status    |
+--------------------------------------------------------------------------------------------+---------------------------------------+-------------+
|  arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0                       |  NO_AVAILABLE_CONFIGURATION_RECORDER  |  INCOMPLETE |
|  arn:aws:securityhub:us-east-1::standards/aws-foundational-security-best-practices/v/1.0.0 |  NO_AVAILABLE_CONFIGURATION_RECORDER  |  INCOMPLETE |
+--------------------------------------------------------------------------------------------+---------------------------------------+-------------+
```

## Safe finding demo (open SSH)
### Simulation: open SSH to the world on a temporary security group
`aws ec2 describe-security-groups --group-ids sg-0f28590b3317cd9e2 --no-cli-pager`
```json
{
    "SecurityGroups": [
        {
            "GroupId": "sg-0f28590b3317cd9e2",
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
            "SecurityGroupArn": "arn:aws:ec2:us-east-1:176087999560:security-group/sg-0f28590b3317cd9e2",
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
    "Findings": []
}
```

### Remediation (remove open ingress)
`aws ec2 describe-security-groups --group-ids sg-0f28590b3317cd9e2 --no-cli-pager`
```json
{
    "SecurityGroups": [
        {
            "GroupId": "sg-0f28590b3317cd9e2",
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
            "SecurityGroupArn": "arn:aws:ec2:us-east-1:176087999560:security-group/sg-0f28590b3317cd9e2",
            "OwnerId": "176087999560",
            "GroupName": "acs-baseline-demo-open-ssh",
            "Description": "Demo misconfig to generate Security Hub finding (temporary)",
            "IpPermissions": []
        }
    ]
}
```

## GuardDuty sample findings (fallback evidence)
`aws guardduty create-sample-findings --detector-id c2db5b53828d466d95f96fc901f93832 --no-cli-pager`

`aws securityhub get-findings --filters <ProductName GuardDuty> --no-cli-pager`
```json
{
    "Findings": [
        {
            "SchemaVersion": "2018-10-08",
            "Id": "arn:aws:guardduty:us-east-1:176087999560:detector/c2db5b53828d466d95f96fc901f93832/finding/aecd9f3bf3543645c3154b30f2661c3a",
            "ProductArn": "arn:aws:securityhub:us-east-1::product/aws/guardduty",
            "ProductName": "GuardDuty",
            "CompanyName": "Amazon",
            "Region": "us-east-1",
            "GeneratorId": "arn:aws:guardduty:us-east-1:176087999560:detector/c2db5b53828d466d95f96fc901f93832",
            "AwsAccountId": "176087999560",
            "Types": [
                "TTPs/Policy:IAMUser-RootCredentialUsage"
            ],
            "FirstObservedAt": "2025-12-21T01:06:24.000Z",
            "LastObservedAt": "2025-12-21T01:07:40.000Z",
            "CreatedAt": "2025-12-21T01:13:23.880Z",
            "UpdatedAt": "2025-12-21T01:13:23.880Z",
            "Severity": {
                "Product": 2.0,
                "Label": "LOW",
                "Normalized": 40
            },
            "Title": "The API GetDetector was invoked using root credentials.",
            "Description": "The API GetDetector was invoked using root credentials from IP address 24.251.38.91.",
            "SourceUrl": "https://us-east-1.console.aws.amazon.com/guardduty/home?region=us-east-1#/findings?macros=current&fId=aecd9f3bf3543645c3154b30f2661c3a",
            "ProductFields": {
                "aws/guardduty/service/archived": "false",
                "aws/guardduty/service/action/awsApiCallAction/remoteIpDetails/organization/asnOrg": "ASN-CXA-ALL-CCI-22773-RDC",
                "aws/guardduty/service/action/awsApiCallAction/remoteIpDetails/organization/org": "Cox Communications",
                "aws/guardduty/service/additionalInfo/value": "",
                "aws/guardduty/service/resourceRole": "TARGET",
                "aws/guardduty/service/action/awsApiCallAction/remoteIpDetails/organization/isp": "Cox Communications",
                "aws/guardduty/service/action/awsApiCallAction/remoteIpDetails/geoLocation/lat": "33.3124",
                "aws/guardduty/service/featureName": "CloudTrailManagementEvent",
                "aws/guardduty/service/count": "18",
                "aws/guardduty/service/action/awsApiCallAction/remoteIpDetails/ipAddressV4": "24.251.38.91",
                "aws/guardduty/service/action/awsApiCallAction/callerType": "Remote IP",
                "aws/guardduty/service/action/awsApiCallAction/remoteIpDetails/country/countryName": "United States",
                "aws/guardduty/service/action/awsApiCallAction/serviceName": "guardduty.amazonaws.com",
                "aws/guardduty/service/additionalInfo/type": "default",
                "aws/guardduty/service/action/awsApiCallAction/remoteIpDetails/city/cityName": "Chandler",
                "aws/guardduty/service/action/awsApiCallAction/api": "GetDetector",
                "aws/guardduty/service/serviceName": "guardduty",
                "aws/guardduty/service/action/awsApiCallAction/remoteIpDetails/geoLocation/lon": "-111.9195",
                "aws/guardduty/service/detectorId": "c2db5b53828d466d95f96fc901f93832",
                "aws/guardduty/service/action/awsApiCallAction/remoteIpDetails/organization/asn": "22773",
                "aws/guardduty/service/action/awsApiCallAction/affectedResources": "",
                "aws/guardduty/service/eventFirstSeen": "2025-12-21T01:06:24.000Z",
                "aws/guardduty/service/eventLastSeen": "2025-12-21T01:07:40.000Z",
                "aws/guardduty/service/action/actionType": "AWS_API_CALL",
                "aws/securityhub/FindingId": "arn:aws:securityhub:us-east-1::product/aws/guardduty/arn:aws:guardduty:us-east-1:176087999560:detector/c2db5b53828d466d95f96fc901f93832/finding/aecd9f3bf3543645c3154b30f2661c3a",
                "aws/securityhub/ProductName": "GuardDuty",
                "aws/securityhub/CompanyName": "Amazon"
            },
            "Resources": [
                {
                    "Type": "AwsIamAccessKey",
                    "Id": "AWS::IAM::AccessKey:ASIASR75JUREFGK6G3JJ",
                    "Partition": "aws",
                    "Region": "us-east-1",
                    "Details": {
                        "AwsIamAccessKey": {
                            "PrincipalId": "176087999560",
                            "PrincipalType": "Root",
                            "PrincipalName": "Root"
                        }
                    }
                }
            ],
            "WorkflowState": "NEW",
            "Workflow": {
                "Status": "NEW"
            },
            "RecordState": "ACTIVE",
            "Action": {
                "ActionType": "AWS_API_CALL",
                "AwsApiCallAction": {
                    "Api": "GetDetector",
                    "ServiceName": "guardduty.amazonaws.com",
                    "CallerType": "remoteIp",
                    "RemoteIpDetails": {
                        "IpAddressV4": "24.251.38.91",
                        "Organization": {
                            "Asn": 22773,
                            "AsnOrg": "ASN-CXA-ALL-CCI-22773-RDC",
                            "Isp": "Cox Communications",
                            "Org": "Cox Communications"
                        },
                        "Country": {
                            "CountryCode": "US",
                            "CountryName": "United States"
                        },
                        "City": {
                            "CityName": "Chandler"
                        },
                        "GeoLocation": {
                            "Lon": -111.9195,
                            "Lat": 33.3124
                        }
                    }
                }
            },
            "FindingProviderFields": {
                "Severity": {
                    "Label": "LOW"
                },
                "Types": [
                    "TTPs/Policy:IAMUser-RootCredentialUsage"
                ]
            },
            "Sample": false,
            "ProcessedAt": "2025-12-21T01:15:04.345Z"
        }
    ]
}
```

## Notes
- AWS Config is enabled, but Security Hub standards may take time to update from NO_AVAILABLE_CONFIGURATION_RECORDER.
- The demo security group was deleted after remediation.
