[CmdletBinding()]
param(
  [ValidateSet("sg", "s3", "iam", "guardduty", "all")]
  [string]$Demo = "all",
  [switch]$Execute,
  [switch]$Force,
  [string]$Region = "us-east-1"
)

$ErrorActionPreference = "Stop"
$env:AWS_PAGER = ""

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$terraformDir = Join-Path $repoRoot "terraform"

function Require-Tool([string]$name) {
  if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
    throw "Missing required tool: $name"
  }
}

function Get-TerraformOutputRaw([string]$name) {
  if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) { return $null }
  if (-not (Test-Path $terraformDir)) { return $null }
  try { return (& terraform -chdir=$terraformDir output -raw $name 2>$null) } catch { return $null }
}

function Print([string]$text) { Write-Output $text }

function Run([string]$command) {
  Print ""
  Print "PS> $command"
  Invoke-Expression $command
}

function Confirm-Execute([string]$label) {
  if (-not $Execute) { return $false }
  if ($Force) { return $true }

  $answer = Read-Host "This will create and delete demo resources in AWS ($label). Type YES to continue"
  return ($answer -eq "YES")
}

function Demo-SgOpenSsh() {
  Print "=== Remediation 1: SG open SSH -> fixed ==="
  Print "See evidence/04-remediation-1-sg-open.md for proof capture."
  Print ""

  $commands = @'
$env:AWS_PAGER=""
$REGION="us-east-1"

cd terraform
$VPC_ID = terraform output -raw flowlogs_vpc_id
cd ..

$ACCOUNT_ID = aws sts get-caller-identity --query Account --output text --no-cli-pager
$NAME = "acs-baseline-demo-open-ssh-$((Get-Date).ToString('yyyyMMddHHmmss'))"

$SG_ID = aws ec2 create-security-group `
  --group-name $NAME `
  --description "Demo misconfig to generate Security Hub control finding (temporary)" `
  --vpc-id $VPC_ID `
  --query GroupId `
  --output text `
  --region $REGION `
  --no-cli-pager

aws ec2 authorize-security-group-ingress `
  --group-id $SG_ID `
  --protocol tcp `
  --port 22 `
  --cidr 0.0.0.0/0 `
  --region $REGION `
  --no-cli-pager

$SG_ARN = "arn:aws:ec2:$REGION:$ACCOUNT_ID:security-group/$SG_ID"

aws ec2 describe-security-groups --group-ids $SG_ID --region $REGION --no-cli-pager
aws securityhub get-findings --filters "{""ResourceId"":[{""Value"":""$SG_ARN"",""Comparison"":""EQUALS""}],""ComplianceStatus"":[{""Value"":""FAILED"",""Comparison"":""EQUALS""}]}" --max-results 10 --region $REGION --no-cli-pager

aws ec2 revoke-security-group-ingress `
  --group-id $SG_ID `
  --protocol tcp `
  --port 22 `
  --cidr 0.0.0.0/0 `
  --region $REGION `
  --no-cli-pager

aws ec2 describe-security-groups --group-ids $SG_ID --region $REGION --no-cli-pager
aws ec2 delete-security-group --group-id $SG_ID --region $REGION --no-cli-pager
aws ec2 describe-security-groups --group-ids $SG_ID --region $REGION --no-cli-pager
'@

  if (-not $Execute) {
    Print $commands
    return
  }

  if (-not (Confirm-Execute "SG open SSH demo")) { return }
  Require-Tool aws
  Require-Tool terraform

  $accountId = (aws sts get-caller-identity --query Account --output text --no-cli-pager)
  $vpcId = Get-TerraformOutputRaw "flowlogs_vpc_id"
  if ([string]::IsNullOrWhiteSpace($vpcId)) { throw "Missing terraform output: flowlogs_vpc_id" }

  $name = "acs-baseline-demo-open-ssh-$((Get-Date).ToString('yyyyMMddHHmmss'))"
  $sgId = (aws ec2 create-security-group --group-name $name --description "Demo misconfig to generate Security Hub control finding (temporary)" --vpc-id $vpcId --query GroupId --output text --region $Region --no-cli-pager)
  aws ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port 22 --cidr 0.0.0.0/0 --region $Region --no-cli-pager | Out-Null

  $sgArn = "arn:aws:ec2:$Region:$accountId:security-group/$sgId"

  aws ec2 describe-security-groups --group-ids $sgId --region $Region --no-cli-pager | Out-Null
  aws securityhub get-findings --filters "{""ResourceId"":[{""Value"":""$sgArn"",""Comparison"":""EQUALS""}],""ComplianceStatus"":[{""Value"":""FAILED"",""Comparison"":""EQUALS""}]}" --max-results 10 --region $Region --no-cli-pager | Out-Null

  aws ec2 revoke-security-group-ingress --group-id $sgId --protocol tcp --port 22 --cidr 0.0.0.0/0 --region $Region --no-cli-pager | Out-Null
  aws ec2 describe-security-groups --group-ids $sgId --region $Region --no-cli-pager | Out-Null
  aws ec2 delete-security-group --group-id $sgId --region $Region --no-cli-pager | Out-Null
}

function Demo-S3Public() {
  Print "=== Remediation 2: S3 public -> private ==="
  Print "See evidence/05-remediation-2-s3-public.md for proof capture."
  Print ""

  $commands = @'
$env:AWS_PAGER=""
$REGION="us-east-1"
$ACCOUNT_ID = aws sts get-caller-identity --query Account --output text --no-cli-pager
$BUCKET="acs-baseline-demo-public-$ACCOUNT_ID"

# Note: us-east-1 create-bucket does NOT use LocationConstraint.
aws s3api create-bucket --bucket $BUCKET --region $REGION --no-cli-pager

aws s3api put-public-access-block `
  --bucket $BUCKET `
  --public-access-block-configuration BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false `
  --region $REGION `
  --no-cli-pager

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

aws s3api put-bucket-policy --bucket $BUCKET --policy file://demo-public-bucket-policy.json --region $REGION --no-cli-pager

aws s3api get-public-access-block --bucket $BUCKET --region $REGION --no-cli-pager
aws s3api get-bucket-policy-status --bucket $BUCKET --region $REGION --no-cli-pager
aws s3api get-bucket-policy --bucket $BUCKET --region $REGION --no-cli-pager

aws s3api delete-bucket-policy --bucket $BUCKET --region $REGION --no-cli-pager
aws s3api put-public-access-block --bucket $BUCKET --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true --region $REGION --no-cli-pager

aws s3api get-public-access-block --bucket $BUCKET --region $REGION --no-cli-pager
aws s3api get-bucket-policy-status --bucket $BUCKET --region $REGION --no-cli-pager

aws s3 rm s3://$BUCKET --recursive --region $REGION --no-cli-pager
aws s3api delete-bucket --bucket $BUCKET --region $REGION --no-cli-pager
aws s3api head-bucket --bucket $BUCKET --region $REGION --no-cli-pager
'@

  if (-not $Execute) {
    Print $commands
    return
  }

  if (-not (Confirm-Execute "S3 public policy demo")) { return }
  Require-Tool aws

  $accountId = (aws sts get-caller-identity --query Account --output text --no-cli-pager)
  $bucket = "acs-baseline-demo-public-$accountId"

  aws s3api create-bucket --bucket $bucket --region $Region --no-cli-pager | Out-Null
  aws s3api put-public-access-block --bucket $bucket --public-access-block-configuration BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false --region $Region --no-cli-pager | Out-Null

  $policyPath = Join-Path $env:TEMP "demo-public-bucket-policy.json"
  @"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::$bucket/*"
    }
  ]
}
"@ | Out-File -Encoding ascii -FilePath $policyPath

  aws s3api put-bucket-policy --bucket $bucket --policy "file://$policyPath" --region $Region --no-cli-pager | Out-Null
  aws s3api get-public-access-block --bucket $bucket --region $Region --no-cli-pager | Out-Null
  aws s3api get-bucket-policy-status --bucket $bucket --region $Region --no-cli-pager | Out-Null

  aws s3api delete-bucket-policy --bucket $bucket --region $Region --no-cli-pager | Out-Null
  aws s3api put-public-access-block --bucket $bucket --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true --region $Region --no-cli-pager | Out-Null

  aws s3 rm "s3://$bucket" --recursive --region $Region --no-cli-pager | Out-Null
  aws s3api delete-bucket --bucket $bucket --region $Region --no-cli-pager | Out-Null
  Remove-Item -Force $policyPath -ErrorAction SilentlyContinue
}

function Demo-IamWildcard() {
  Print "=== Remediation 3: IAM wildcard -> least privilege ==="
  Print "See evidence/06-remediation-3-iam-wildcards.md for proof capture."
  Print ""

  $commands = @'
$env:AWS_PAGER=""
cd terraform
$FIXED_POLICY_ARN = terraform output -raw fixed_policy_arn
$BAD_POLICY_ARN = terraform output -raw bad_policy_arn
cd ..

# If bad_policy_arn is empty/null, enable the demo-only policy and apply:
#   cd terraform
#   terraform apply -var="create_bad_policy_example=true"
#   terraform output -raw bad_policy_arn

$ROLE="acs-baseline-demo-bad-iam-$((Get-Date).ToString('yyyyMMddHHmmss'))"
$ACCOUNT_ID = aws sts get-caller-identity --query Account --output text --no-cli-pager

@"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "AWS": "arn:aws:iam::$ACCOUNT_ID:root" },
      "Action": "sts:AssumeRole"
    }
  ]
}
"@ | Out-File -Encoding ascii -FilePath .\\trust-demo-role.json

aws iam create-role --role-name $ROLE --assume-role-policy-document file://trust-demo-role.json --no-cli-pager
aws iam attach-role-policy --role-name $ROLE --policy-arn $BAD_POLICY_ARN --no-cli-pager

aws iam list-attached-role-policies --role-name $ROLE --no-cli-pager
aws iam get-policy-version --policy-arn $BAD_POLICY_ARN --version-id v1 --no-cli-pager

aws iam detach-role-policy --role-name $ROLE --policy-arn $BAD_POLICY_ARN --no-cli-pager
aws iam attach-role-policy --role-name $ROLE --policy-arn $FIXED_POLICY_ARN --no-cli-pager

aws iam list-attached-role-policies --role-name $ROLE --no-cli-pager
aws iam get-policy-version --policy-arn $FIXED_POLICY_ARN --version-id v1 --no-cli-pager

aws iam detach-role-policy --role-name $ROLE --policy-arn $FIXED_POLICY_ARN --no-cli-pager
aws iam delete-role --role-name $ROLE --no-cli-pager
aws iam get-role --role-name $ROLE --no-cli-pager
'@

  if (-not $Execute) {
    Print $commands
    return
  }

  if (-not (Confirm-Execute "IAM wildcard demo role")) { return }
  Require-Tool aws
  Require-Tool terraform

  $fixedPolicyArn = Get-TerraformOutputRaw "fixed_policy_arn"
  $badPolicyArn = Get-TerraformOutputRaw "bad_policy_arn"
  if ([string]::IsNullOrWhiteSpace($badPolicyArn)) {
    throw "bad_policy_arn is empty/null. Run: cd terraform; terraform apply -var=\"create_bad_policy_example=true\""
  }

  $accountId = (aws sts get-caller-identity --query Account --output text --no-cli-pager)
  $role = "acs-baseline-demo-bad-iam-$((Get-Date).ToString('yyyyMMddHHmmss'))"

  $trustPath = Join-Path $env:TEMP "trust-demo-role.json"
  @"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "AWS": "arn:aws:iam::$accountId:root" },
      "Action": "sts:AssumeRole"
    }
  ]
}
"@ | Out-File -Encoding ascii -FilePath $trustPath

  aws iam create-role --role-name $role --assume-role-policy-document "file://$trustPath" --no-cli-pager | Out-Null
  aws iam attach-role-policy --role-name $role --policy-arn $badPolicyArn --no-cli-pager | Out-Null
  aws iam list-attached-role-policies --role-name $role --no-cli-pager | Out-Null

  aws iam detach-role-policy --role-name $role --policy-arn $badPolicyArn --no-cli-pager | Out-Null
  aws iam attach-role-policy --role-name $role --policy-arn $fixedPolicyArn --no-cli-pager | Out-Null
  aws iam list-attached-role-policies --role-name $role --no-cli-pager | Out-Null

  aws iam detach-role-policy --role-name $role --policy-arn $fixedPolicyArn --no-cli-pager | Out-Null
  aws iam delete-role --role-name $role --no-cli-pager | Out-Null

  Remove-Item -Force $trustPath -ErrorAction SilentlyContinue
}

function Demo-GuardDutySamples() {
  Print "=== Detection fallback: GuardDuty sample findings -> Security Hub ingestion ==="
  Print "See evidence/03-detection-findings.md for proof capture."
  Print ""

  $commands = @"
$env:AWS_PAGER=""
cd terraform
$DETECTOR_ID = terraform output -raw guardduty_detector_id
cd ..

aws guardduty create-sample-findings --detector-id $DETECTOR_ID --region $Region --no-cli-pager

@'
{
  \"ProductName\": [
    { \"Value\": \"GuardDuty\", \"Comparison\": \"EQUALS\" }
  ]
}
'@ | Out-File -Encoding ascii -FilePath .\\filters-guardduty.json

aws securityhub get-findings --filters file://filters-guardduty.json --max-results 5 --region $Region --no-cli-pager
"@

  if (-not $Execute) {
    Print $commands
    return
  }

  if (-not (Confirm-Execute "GuardDuty sample findings")) { return }
  Require-Tool aws
  Require-Tool terraform

  $detectorId = Get-TerraformOutputRaw "guardduty_detector_id"
  if ([string]::IsNullOrWhiteSpace($detectorId)) { throw "Missing terraform output: guardduty_detector_id" }

  aws guardduty create-sample-findings --detector-id $detectorId --region $Region --no-cli-pager | Out-Null
  aws securityhub get-findings --filters "{""ProductName"":[{""Value"":""GuardDuty"",""Comparison"":""EQUALS""}]}" --max-results 5 --region $Region --no-cli-pager | Out-Null
}

if ($Demo -in @("sg", "all")) { Demo-SgOpenSsh }
if ($Demo -in @("s3", "all")) { Demo-S3Public }
if ($Demo -in @("iam", "all")) { Demo-IamWildcard }
if ($Demo -in @("guardduty", "all")) { Demo-GuardDutySamples }

