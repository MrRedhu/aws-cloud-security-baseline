# Remediation 2 - S3 public access exposure (bucket policy / ACL)

## Issue
S3 buckets are a common data exposure vector. This remediation demonstrates detecting and fixing a public-access misconfiguration safely.

## Detection signal (expected)
- Security Hub S3 public access related control(s)
- Compliance: FAILED

## BEFORE evidence
`aws s3api get-public-access-block --bucket acs-baseline-demo-public-176087999560 --region us-east-1 --no-cli-pager`
```json
{
    "PublicAccessBlockConfiguration": {
        "BlockPublicAcls": false,
        "IgnorePublicAcls": false,
        "BlockPublicPolicy": false,
        "RestrictPublicBuckets": false
    }
}
```

`aws s3api get-bucket-policy-status --bucket acs-baseline-demo-public-176087999560 --region us-east-1 --no-cli-pager`
```json
{
    "PolicyStatus": {
        "IsPublic": true
    }
}
```

`aws s3api get-bucket-policy --bucket acs-baseline-demo-public-176087999560 --region us-east-1 --no-cli-pager`
```json
{
    "Policy": "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"PublicReadGetObject\",\"Effect\":\"Allow\",\"Principal\":\"*\",\"Action\":\"s3:GetObject\",\"Resource\":\"arn:aws:s3:::acs-baseline-demo-public-176087999560/*\"}]}"
}
```

`aws securityhub get-findings --filters file://filters-s3-this.json --max-results 20 --region us-east-1 --no-cli-pager`
```json
{
    "Findings": []
}
```

## Remediation
- Enabled Block Public Access at the bucket level
- Removed the public bucket policy

## AFTER evidence
`aws s3api get-public-access-block --bucket acs-baseline-demo-public-176087999560 --region us-east-1 --no-cli-pager`
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

`aws s3api get-bucket-policy-status --bucket acs-baseline-demo-public-176087999560 --region us-east-1 --no-cli-pager`
```
An error occurred (NoSuchBucketPolicy) when calling the GetBucketPolicyStatus operation: The bucket policy does not exist
```

## Prevention
- Enforce Block Public Access by default for new buckets
- Periodic Security Hub checks + alerts
- Policy-as-code checks for S3 policies in CI
