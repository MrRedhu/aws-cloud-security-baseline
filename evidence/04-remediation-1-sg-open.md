# Remediation 1 - EC2 Security Group open to the world (SSH)

## Issue
Inbound SSH (TCP/22) was open to 0.0.0.0/0, increasing exposure and brute-force risk.

## Detection signal
- Security Hub control: EC2.18 (Security groups should only allow unrestricted incoming traffic for authorized ports)
- Severity: HIGH
- Compliance: FAILED

## BEFORE evidence
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

## Remediation
Removed inbound rule allowing 0.0.0.0/0 on port 22.

## Change (diff)
- Inbound: tcp/22 from 0.0.0.0/0
+ Inbound: none

## AFTER evidence
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

## Prevention
- Use least-privilege SG rules (restrict by CIDR/VPN/bastion)
- Keep Security Hub FSBP enabled to detect regressions
- Consider policy-as-code checks for SG rules in CI
