# Logging Baseline - Evidence (CloudTrail + Flow Logs + Retention + Hardened Storage)

## Goal
Prove that logging is:
- Enabled (CloudTrail + VPC Flow Logs)
- Centralized (CloudWatch Logs + S3 archive bucket for CloudTrail)
- Retained (CloudWatch retention policies set)
- Hardened (S3 Block Public Access + encryption + versioning)

## S3 Log Archive Bucket (hardened storage)
`aws s3api get-public-access-block --bucket acs-baseline-176087999560-log-archive --no-cli-pager`
```json
{
    "PublicAccessBlockConfiguration": {
        "BlockPublicAcls": true,
        "IgnorePublicAcls": true,
        "BlockPublicPolicy": true,
        "RestrictPublicBuckets": true
    }
}
```

`aws s3api get-bucket-encryption --bucket acs-baseline-176087999560-log-archive --no-cli-pager`
```json
{
    "ServerSideEncryptionConfiguration": {
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                },
                "BucketKeyEnabled": false
            }
        ]
    }
}
```

`aws s3api get-bucket-versioning --bucket acs-baseline-176087999560-log-archive --no-cli-pager`
```json
{
    "Status": "Enabled"
}
```

`aws s3api get-bucket-policy --bucket acs-baseline-176087999560-log-archive --no-cli-pager`
```json
{
    "Policy": "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"AWSCloudTrailAclCheck\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"cloudtrail.amazonaws.com\"},\"Action\":\"s3:GetBucketAcl\",\"Resource\":\"arn:aws:s3:::acs-baseline-176087999560-log-archive\"},{\"Sid\":\"AWSCloudTrailWrite\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"cloudtrail.amazonaws.com\"},\"Action\":\"s3:PutObject\",\"Resource\":\"arn:aws:s3:::acs-baseline-176087999560-log-archive/AWSLogs/176087999560/*\",\"Condition\":{\"StringEquals\":{\"s3:x-amz-acl\":\"bucket-owner-full-control\"}}}]}"
}
```

## CloudTrail (API activity logging)
`aws cloudtrail get-trail-status --name acs-baseline-trail --no-cli-pager`
```json
{
    "IsLogging": true,
    "LatestDeliveryTime": "2025-12-20T17:54:13.137000-07:00",
    "StartLoggingTime": "2025-12-20T17:50:43.963000-07:00",
    "LatestCloudWatchLogsDeliveryTime": "2025-12-20T17:56:04.677000-07:00",
    "LatestDeliveryAttemptTime": "2025-12-21T00:54:13Z",
    "LatestNotificationAttemptTime": "",
    "LatestNotificationAttemptSucceeded": "",
    "LatestDeliveryAttemptSucceeded": "2025-12-21T00:54:13Z",
    "TimeLoggingStarted": "2025-12-21T00:50:43Z",
    "TimeLoggingStopped": ""
}
```

`aws cloudtrail describe-trails --no-cli-pager`
```json
{
    "trailList": [
        {
            "Name": "acs-baseline-trail",
            "S3BucketName": "acs-baseline-176087999560-log-archive",
            "IncludeGlobalServiceEvents": true,
            "IsMultiRegionTrail": true,
            "HomeRegion": "us-east-1",
            "TrailARN": "arn:aws:cloudtrail:us-east-1:176087999560:trail/acs-baseline-trail",
            "LogFileValidationEnabled": true,
            "CloudWatchLogsLogGroupArn": "arn:aws:logs:us-east-1:176087999560:log-group:/aws/cloudtrail/acs-baseline:*",
            "CloudWatchLogsRoleArn": "arn:aws:iam::176087999560:role/acs-baseline-cloudtrail-cw-role",
            "HasCustomEventSelectors": false,
            "HasInsightSelectors": false,
            "IsOrganizationTrail": false
        }
    ]
}
```

## VPC Flow Logs (network visibility)
`aws ec2 describe-flow-logs --no-cli-pager`
```json
{
    "FlowLogs": [
        {
            "CreationTime": "2025-12-21T00:50:44.273000+00:00",
            "DeliverLogsPermissionArn": "arn:aws:iam::176087999560:role/acs-baseline-flowlogs-cw-role",
            "DeliverLogsStatus": "SUCCESS",
            "FlowLogId": "fl-077fd3b81d0669eca",
            "FlowLogStatus": "ACTIVE",
            "LogGroupName": "/aws/vpc/flowlogs/acs-baseline",
            "ResourceId": "vpc-035de9c63c12c4cc2",
            "TrafficType": "ALL",
            "LogDestinationType": "cloud-watch-logs",
            "LogDestination": "arn:aws:logs:us-east-1:176087999560:log-group:/aws/vpc/flowlogs/acs-baseline",
            "LogFormat": "${version} ${account-id} ${interface-id} ${srcaddr} ${dstaddr} ${srcport} ${dstport} ${protocol} ${packets} ${bytes} ${start} ${end} ${action} ${log-status}",
            "Tags": [
                {
                    "Key": "Env",
                    "Value": "dev"
                },
                {
                    "Key": "Project",
                    "Value": "aws-cloud-security-baseline"
                },
                {
                    "Key": "Owner",
                    "Value": "emerson"
                }
            ],
            "MaxAggregationInterval": 600
        }
    ]
}
```

## Retention (CloudWatch Logs)
`aws logs describe-log-groups --log-group-name-prefix "/aws/cloudtrail/acs-baseline" --query "logGroups[].{name:logGroupName,retention:retentionInDays}" --output table --no-cli-pager`
```
-----------------------------------------------
|              DescribeLogGroups              |
+-------------------------------+-------------+
|             name              |  retention  |
+-------------------------------+-------------+
|  /aws/cloudtrail/acs-baseline |  30         |
+-------------------------------+-------------+
```

`aws logs describe-log-groups --log-group-name-prefix "/aws/vpc/flowlogs/acs-baseline" --query "logGroups[].{name:logGroupName,retention:retentionInDays}" --output table --no-cli-pager`
```
-------------------------------------------------
|               DescribeLogGroups               |
+---------------------------------+-------------+
|              name               |  retention  |
+---------------------------------+-------------+
|  /aws/vpc/flowlogs/acs-baseline |  30         |
+---------------------------------+-------------+
```

Retention evidence is filtered to baseline log groups (/aws/cloudtrail/acs-baseline and /aws/vpc/flowlogs/acs-baseline) to avoid unrelated pre-existing log groups in the account.

## Notes
- CloudTrail also writes to S3 under `AWSLogs/176087999560/`.
- Findings and incident response will rely on these logs in later steps.
