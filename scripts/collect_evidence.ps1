[CmdletBinding()]
param(
  [switch]$Execute,
  [string]$Region = "us-east-1"
)

$ErrorActionPreference = "Stop"
$env:AWS_PAGER = ""

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$terraformDir = Join-Path $repoRoot "terraform"

function Test-Tool([string]$name) {
  return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

function Get-TerraformOutputRaw([string]$name) {
  if (-not (Test-Tool "terraform")) { return $null }
  if (-not (Test-Path $terraformDir)) { return $null }

  try {
    return (& terraform -chdir=$terraformDir output -raw $name 2>$null)
  } catch {
    return $null
  }
}

$logBucket = Get-TerraformOutputRaw "log_bucket_name"
$configBucket = Get-TerraformOutputRaw "config_bucket_name"
$trailName = Get-TerraformOutputRaw "cloudtrail_name"
$badPolicyArn = Get-TerraformOutputRaw "bad_policy_arn"
$fixedPolicyArn = Get-TerraformOutputRaw "fixed_policy_arn"
$detectorId = Get-TerraformOutputRaw "guardduty_detector_id"

Write-Output "AWS Cloud Security Baseline - Evidence Command Helper"
Write-Output ""
Write-Output "Prereqs:"
Write-Output "  - Authenticate AWS CLI (recommended: set `$env:AWS_PAGER=\"\" for clean output)"
Write-Output "  - Terraform applied at least once (so `terraform output` exists)"
Write-Output ""

Write-Output "--- Resolved placeholders (from terraform output, when available) ---"
if ($logBucket) { Write-Output "LOG_BUCKET=$logBucket" }
if ($configBucket) { Write-Output "CONFIG_BUCKET=$configBucket" }
if ($trailName) { Write-Output "TRAIL_NAME=$trailName" }
if ($badPolicyArn) { Write-Output "BAD_POLICY_ARN=$badPolicyArn" }
if ($fixedPolicyArn) { Write-Output "FIXED_POLICY_ARN=$fixedPolicyArn" }
if ($detectorId) { Write-Output "DETECTOR_ID=$detectorId" }
Write-Output ""

function Print-Command([string]$command) {
  Write-Output $command
}

function Run-Command([string]$command) {
  Write-Output ""
  Write-Output "PS> $command"
  Invoke-Expression $command
}

$commands = @()

$commands += "cd terraform"
$commands += "terraform output"
$commands += ""
$commands += "aws sts get-caller-identity --no-cli-pager"

$commands += ""
$commands += "# Step 3 (IAM)"
$commands += "aws iam list-attached-role-policies --role-name acs-baseline-developer-role --no-cli-pager"
$commands += "aws iam get-policy-version --policy-arn $([string]::IsNullOrWhiteSpace($badPolicyArn) ? '<BAD_POLICY_ARN>' : $badPolicyArn) --version-id v1 --no-cli-pager"
$commands += "aws iam get-policy-version --policy-arn $([string]::IsNullOrWhiteSpace($fixedPolicyArn) ? '<FIXED_POLICY_ARN>' : $fixedPolicyArn) --version-id v1 --no-cli-pager"

$commands += ""
$commands += "# Step 4 (Logging)"
$commands += "aws s3api get-public-access-block --bucket $([string]::IsNullOrWhiteSpace($logBucket) ? '<LOG_BUCKET>' : $logBucket) --no-cli-pager"
$commands += "aws s3api get-bucket-ownership-controls --bucket $([string]::IsNullOrWhiteSpace($logBucket) ? '<LOG_BUCKET>' : $logBucket) --no-cli-pager"
$commands += "aws s3api get-bucket-encryption --bucket $([string]::IsNullOrWhiteSpace($logBucket) ? '<LOG_BUCKET>' : $logBucket) --no-cli-pager"
$commands += "aws s3api get-bucket-versioning --bucket $([string]::IsNullOrWhiteSpace($logBucket) ? '<LOG_BUCKET>' : $logBucket) --no-cli-pager"
$commands += "aws s3api get-bucket-policy --bucket $([string]::IsNullOrWhiteSpace($logBucket) ? '<LOG_BUCKET>' : $logBucket) --no-cli-pager"
$commands += "aws cloudtrail describe-trails --region $Region --no-cli-pager"
$commands += "aws cloudtrail get-trail-status --name $([string]::IsNullOrWhiteSpace($trailName) ? '<TRAIL_NAME>' : $trailName) --region $Region --no-cli-pager"
$commands += "aws logs describe-log-groups --log-group-name-prefix /aws/cloudtrail/acs-baseline --region $Region --no-cli-pager"
$commands += "aws ec2 describe-flow-logs --region $Region --no-cli-pager"
$commands += "aws logs describe-log-groups --log-group-name-prefix /aws/vpc/flowlogs/acs-baseline --region $Region --no-cli-pager"

$commands += ""
$commands += "# Step 5 (Detection + Config)"
$commands += "aws guardduty list-detectors --region $Region --no-cli-pager"
$commands += "aws guardduty get-detector --detector-id $([string]::IsNullOrWhiteSpace($detectorId) ? '<DETECTOR_ID>' : $detectorId) --region $Region --no-cli-pager"
$commands += "aws securityhub describe-hub --region $Region --no-cli-pager"
$commands += "aws securityhub get-enabled-standards --region $Region --no-cli-pager"
$commands += "aws configservice describe-configuration-recorder-status --region $Region --no-cli-pager"
$commands += "aws configservice describe-configuration-recorders --region $Region --no-cli-pager"
$commands += "aws configservice describe-delivery-channels --region $Region --no-cli-pager"
$commands += "aws s3api get-public-access-block --bucket $([string]::IsNullOrWhiteSpace($configBucket) ? '<CONFIG_BUCKET>' : $configBucket) --no-cli-pager"
$commands += "aws s3api get-bucket-ownership-controls --bucket $([string]::IsNullOrWhiteSpace($configBucket) ? '<CONFIG_BUCKET>' : $configBucket) --no-cli-pager"
$commands += "aws s3api get-bucket-encryption --bucket $([string]::IsNullOrWhiteSpace($configBucket) ? '<CONFIG_BUCKET>' : $configBucket) --no-cli-pager"
$commands += "aws s3api get-bucket-versioning --bucket $([string]::IsNullOrWhiteSpace($configBucket) ? '<CONFIG_BUCKET>' : $configBucket) --no-cli-pager"
$commands += "aws s3api get-bucket-policy --bucket $([string]::IsNullOrWhiteSpace($configBucket) ? '<CONFIG_BUCKET>' : $configBucket) --no-cli-pager"

$commands += ""
$commands += "# Step 6/7 (Remediations)"
$commands += "# See:"
$commands += "#  - evidence/04-remediation-1-sg-open.md"
$commands += "#  - evidence/05-remediation-2-s3-public.md"
$commands += "#  - evidence/06-remediation-3-iam-wildcards.md"

if (-not $Execute) {
  $commands | ForEach-Object { Print-Command $_ }
  exit 0
}

if (-not (Test-Tool "aws")) {
  throw "AWS CLI not found on PATH."
}
if (-not (Test-Tool "terraform")) {
  throw "Terraform not found on PATH."
}

foreach ($cmd in $commands) {
  if ([string]::IsNullOrWhiteSpace($cmd)) { continue }
  if ($cmd.StartsWith("#")) { continue }
  if ($cmd -match "<[^>]+>") {
    Write-Output ""
    Write-Output "SKIP (unresolved placeholder): $cmd"
    continue
  }
  Run-Command $cmd
}
