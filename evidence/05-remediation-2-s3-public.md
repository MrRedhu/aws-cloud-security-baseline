# Remediation 2 - S3 public access exposure (bucket policy / ACL)

## Reproduce (safe demo)
This demo creates a temporary S3 bucket, intentionally makes it public via bucket policy + disabled Block Public Access, then remediates by removing the policy and re-enabling Block Public Access.

### 1) Simulate misconfiguration (public bucket policy)
```powershell
$env:AWS_PAGER=""
$REGION="us-east-1"
$ACCOUNT_ID = aws sts get-caller-identity --query Account --output text --no-cli-pager
$BUCKET="acs-baseline-demo-public-$ACCOUNT_ID"

# Note: us-east-1 create-bucket does NOT use LocationConstraint.
aws s3api create-bucket --bucket $BUCKET --region $REGION --no-cli-pager

# Disable Block Public Access (demo only)
aws s3api put-public-access-block `
  --bucket $BUCKET `
  --public-access-block-configuration BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false `
  --region $REGION `
  --no-cli-pager

# Apply a public read bucket policy (demo only)
@"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::$BUCKET/*"
    }
  ]
}
"@ | Out-File -Encoding ascii -FilePath .\\demo-public-bucket-policy.json

aws s3api put-bucket-policy `
  --bucket $BUCKET `
  --policy file://demo-public-bucket-policy.json `
  --region $REGION `
  --no-cli-pager
```

### 2) Verify-before (proof)
```powershell
aws s3api get-public-access-block --bucket $BUCKET --region $REGION --no-cli-pager
aws s3api get-bucket-policy-status --bucket $BUCKET --region $REGION --no-cli-pager
aws s3api get-bucket-policy --bucket $BUCKET --region $REGION --no-cli-pager

# Optional: Security Hub controls can take time; filter may be empty initially.
@"
{
  "ResourceId": [
    { "Value": "arn:aws:s3:::$BUCKET", "Comparison": "EQUALS" }
  ]
}
"@ | Out-File -Encoding ascii -FilePath .\\filters-s3-this.json

aws securityhub get-findings `
  --filters file://filters-s3-this.json `
  --max-results 20 `
  --region $REGION `
  --no-cli-pager
```

### 3) Fix (remove public policy + re-enable Block Public Access)
```powershell
aws s3api delete-bucket-policy --bucket $BUCKET --region $REGION --no-cli-pager

aws s3api put-public-access-block `
  --bucket $BUCKET `
  --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true `
  --region $REGION `
  --no-cli-pager
```

### 4) Verify-after (proof) + cleanup
```powershell
aws s3api get-public-access-block --bucket $BUCKET --region $REGION --no-cli-pager
aws s3api get-bucket-policy-status --bucket $BUCKET --region $REGION --no-cli-pager

# Cleanup (bucket must be empty)
aws s3 rm s3://$BUCKET --recursive --region $REGION --no-cli-pager
aws s3api delete-bucket --bucket $BUCKET --region $REGION --no-cli-pager
aws s3api head-bucket --bucket $BUCKET --region $REGION --no-cli-pager
```

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

Control evaluation can take several minutes; this demo validates risk + fix via AWS-native policy status and BPA configuration.

## Remediation
- Enabled Block Public Access at the bucket level
- Removed the public bucket policy

## Change (diff)
- BlockPublicAcls/IgnorePublicAcls/BlockPublicPolicy/RestrictPublicBuckets: false
+ BlockPublicAcls/IgnorePublicAcls/BlockPublicPolicy/RestrictPublicBuckets: true
- Public bucket policy: Allow s3:GetObject to "*"
+ Bucket policy removed

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

## Cleanup proof
`aws s3api head-bucket --bucket acs-baseline-demo-public-176087999560 --region us-east-1 --no-cli-pager`
```
An error occurred (404) when calling the HeadBucket operation: Not Found
```

## Cleanup recheck
`aws s3api head-bucket --bucket acs-baseline-demo-public-176087999560 --region us-east-1 --no-cli-pager`
```
An error occurred (404) when calling the HeadBucket operation: Not Found
```

## Prevention
- Enforce Block Public Access by default for new buckets
- Periodic Security Hub checks + alerts
- Policy-as-code checks for S3 policies in CI
