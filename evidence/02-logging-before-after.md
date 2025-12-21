# Logging Baseline - Evidence (CloudTrail + Flow Logs + Retention + Hardened Storage)

## Goal
Prove that logging is:
- Enabled (CloudTrail + VPC Flow Logs)
- Centralized (CloudWatch Logs + S3 archive bucket for CloudTrail)
- Retained (CloudWatch retention policies set)
- Hardened (S3 Block Public Access + encryption + versioning)

## S3 Log Archive Bucket (hardened storage)
`aws s3api get-public-access-block --bucket acs-baseline-176087999560-log-archive`
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

`aws s3api get-bucket-encryption --bucket acs-baseline-176087999560-log-archive`
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

`aws s3api get-bucket-versioning --bucket acs-baseline-176087999560-log-archive`
```json
{
    "Status": "Enabled"
}
```

`aws s3api get-bucket-policy --bucket acs-baseline-176087999560-log-archive`
```json
{
    "Policy": "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"AWSCloudTrailAclCheck\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"cloudtrail.amazonaws.com\"},\"Action\":\"s3:GetBucketAcl\",\"Resource\":\"arn:aws:s3:::acs-baseline-176087999560-log-archive\"},{\"Sid\":\"AWSCloudTrailWrite\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"cloudtrail.amazonaws.com\"},\"Action\":\"s3:PutObject\",\"Resource\":\"arn:aws:s3:::acs-baseline-176087999560-log-archive/AWSLogs/176087999560/*\",\"Condition\":{\"StringEquals\":{\"s3:x-amz-acl\":\"bucket-owner-full-control\"}}}]}"
}
```

## CloudTrail (API activity logging)
`aws cloudtrail describe-trails`
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

`aws cloudtrail get-trail-status --name acs-baseline-trail`
```json
{
    "IsLogging": true,
    "StartLoggingTime": "2025-12-20T17:50:43.963000-07:00",
    "LatestDeliveryAttemptTime": "",
    "LatestNotificationAttemptTime": "",
    "LatestNotificationAttemptSucceeded": "",
    "LatestDeliveryAttemptSucceeded": "",
    "TimeLoggingStarted": "2025-12-21T00:50:43Z",
    "TimeLoggingStopped": ""
}
```

`aws logs describe-log-groups --log-group-name-prefix /aws/cloudtrail/`
```json
{
    "logGroups": [
        {
            "logGroupName": "/aws/cloudtrail/acs-baseline",
            "creationTime": 1766278231894,
            "retentionInDays": 30,
            "metricFilterCount": 0,
            "arn": "arn:aws:logs:us-east-1:176087999560:log-group:/aws/cloudtrail/acs-baseline:*",
            "storedBytes": 0,
            "logGroupClass": "STANDARD",
            "logGroupArn": "arn:aws:logs:us-east-1:176087999560:log-group:/aws/cloudtrail/acs-baseline",
            "deletionProtectionEnabled": false
        }
    ]
}
```

## VPC Flow Logs (network visibility)
`aws ec2 describe-flow-logs`
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

`aws logs describe-log-groups --log-group-name-prefix /aws/vpc/flowlogs/`
```json
{
    "logGroups": [
        {
            "logGroupName": "/aws/vpc/flowlogs/acs-baseline",
            "creationTime": 1766278231910,
            "retentionInDays": 30,
            "metricFilterCount": 0,
            "arn": "arn:aws:logs:us-east-1:176087999560:log-group:/aws/vpc/flowlogs/acs-baseline:*",
            "storedBytes": 0,
            "logGroupClass": "STANDARD",
            "logGroupArn": "arn:aws:logs:us-east-1:176087999560:log-group:/aws/vpc/flowlogs/acs-baseline",
            "deletionProtectionEnabled": false
        }
    ]
}
```

## Retention (CloudWatch Logs)
`aws logs describe-log-groups --log-group-name-prefix /aws/`
```json
{
    "logGroups": [
        {
            "logGroupName": "/aws/cloudtrail/acs-baseline",
            "creationTime": 1766278231894,
            "retentionInDays": 30,
            "metricFilterCount": 0,
            "arn": "arn:aws:logs:us-east-1:176087999560:log-group:/aws/cloudtrail/acs-baseline:*",
            "storedBytes": 0,
            "logGroupClass": "STANDARD",
            "logGroupArn": "arn:aws:logs:us-east-1:176087999560:log-group:/aws/cloudtrail/acs-baseline",
            "deletionProtectionEnabled": false
        },
        {
            "logGroupName": "/aws/lambda/face-detection",
            "creationTime": 1763164356149,
            "metricFilterCount": 0,
            "arn": "arn:aws:logs:us-east-1:176087999560:log-group:/aws/lambda/face-detection:*",
            "storedBytes": 1016904,
            "logGroupClass": "STANDARD",
            "logGroupArn": "arn:aws:logs:us-east-1:176087999560:log-group:/aws/lambda/face-detection",
            "deletionProtectionEnabled": false
        },
        {
            "logGroupName": "/aws/lambda/face-recognition",
            "creationTime": 1763168382217,
            "metricFilterCount": 0,
            "arn": "arn:aws:logs:us-east-1:176087999560:log-group:/aws/lambda/face-recognition:*",
            "storedBytes": 3282476,
            "logGroupClass": "STANDARD",
            "logGroupArn": "arn:aws:logs:us-east-1:176087999560:log-group:/aws/lambda/face-recognition",
            "deletionProtectionEnabled": false
        },
        {
            "logGroupName": "/aws/vpc/flowlogs/acs-baseline",
            "creationTime": 1766278231910,
            "retentionInDays": 30,
            "metricFilterCount": 0,
            "arn": "arn:aws:logs:us-east-1:176087999560:log-group:/aws/vpc/flowlogs/acs-baseline:*",
            "storedBytes": 0,
            "logGroupClass": "STANDARD",
            "logGroupArn": "arn:aws:logs:us-east-1:176087999560:log-group:/aws/vpc/flowlogs/acs-baseline",
            "deletionProtectionEnabled": false
        }
    ]
}
```

## Notes
- CloudTrail also writes to S3 under `AWSLogs/176087999560/`.
- This output includes unrelated log groups that pre-existed in the account and may not have retention configured.
- Findings and incident response will rely on these logs in later steps.
