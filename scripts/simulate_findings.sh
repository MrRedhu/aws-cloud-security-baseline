#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${REPO_ROOT}/terraform"

EXECUTE=0
DEMO="all"
REGION="${AWS_REGION:-us-east-1}"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/simulate_findings.sh [--demo sg|s3|iam|guardduty|all] [--execute]

Default behavior prints commands (no cloud actions). Use --execute to run the demo(s).
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --demo)
      DEMO="${2:-}"
      shift 2
      ;;
    --execute)
      EXECUTE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown arg: $1" >&2
      usage
      exit 2
      ;;
  esac
done

run() {
  if [ "$EXECUTE" -eq 1 ]; then
    echo "+ $*"
    "$@"
  else
    printf '+ %q ' "$@"
    printf '\n'
  fi
}

tf_output() {
  (cd "$TF_DIR" && terraform output -raw "$1" 2>/dev/null || true)
}

require_tools() {
  for t in "$@"; do
    command -v "$t" >/dev/null 2>&1 || { echo "Missing required tool: $t" >&2; exit 1; }
  done
}

print_header() {
  echo
  echo "=== $1 ==="
}

demo_sg() {
  print_header "Remediation 1: SG open SSH -> fixed"
  if [ "$EXECUTE" -eq 0 ]; then
    cat <<'EOF'
export AWS_PAGER=""
REGION="us-east-1"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text --no-cli-pager)"
VPC_ID="$(cd terraform && terraform output -raw flowlogs_vpc_id)"
NAME="acs-baseline-demo-open-ssh-$(date +%Y%m%d%H%M%S)"

SG_ID="$(aws ec2 create-security-group \
  --group-name "$NAME" \
  --description "Demo misconfig to generate Security Hub control finding (temporary)" \
  --vpc-id "$VPC_ID" \
  --query GroupId \
  --output text \
  --region "$REGION" \
  --no-cli-pager)"

aws ec2 authorize-security-group-ingress \
  --group-id "$SG_ID" \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0 \
  --region "$REGION" \
  --no-cli-pager

SG_ARN="arn:aws:ec2:$REGION:$ACCOUNT_ID:security-group/$SG_ID"

aws ec2 describe-security-groups --group-ids "$SG_ID" --region "$REGION" --no-cli-pager

cat > /tmp/filters-sg-ec2-18.json <<JSON
{
  "ResourceId": [{ "Value": "$SG_ARN", "Comparison": "EQUALS" }],
  "ComplianceStatus": [{ "Value": "FAILED", "Comparison": "EQUALS" }]
}
JSON

aws securityhub get-findings \
  --filters file:///tmp/filters-sg-ec2-18.json \
  --max-results 10 \
  --region "$REGION" \
  --no-cli-pager

aws ec2 revoke-security-group-ingress \
  --group-id "$SG_ID" \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0 \
  --region "$REGION" \
  --no-cli-pager

aws ec2 describe-security-groups --group-ids "$SG_ID" --region "$REGION" --no-cli-pager
aws ec2 delete-security-group --group-id "$SG_ID" --region "$REGION" --no-cli-pager
aws ec2 describe-security-groups --group-ids "$SG_ID" --region "$REGION" --no-cli-pager
EOF
    return
  fi

require_tools aws terraform
export AWS_PAGER=""

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text --no-cli-pager)"
VPC_ID="$(tf_output flowlogs_vpc_id)"
NAME="acs-baseline-demo-open-ssh-$(date +%Y%m%d%H%M%S)"

SG_ID="$(aws ec2 create-security-group \
  --group-name "$NAME" \
  --description "Demo misconfig to generate Security Hub control finding (temporary)" \
  --vpc-id "$VPC_ID" \
  --query GroupId \
  --output text \
  --region "$REGION" \
  --no-cli-pager)"

run aws ec2 authorize-security-group-ingress \
  --group-id "$SG_ID" \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0 \
  --region "$REGION" \
  --no-cli-pager

run aws ec2 describe-security-groups --group-ids "$SG_ID" --region "$REGION" --no-cli-pager

SG_ARN="arn:aws:ec2:$REGION:$ACCOUNT_ID:security-group/$SG_ID"
FILTER="$(mktemp)"
cat > "$FILTER" <<JSON
{
  "ResourceId": [{ "Value": "$SG_ARN", "Comparison": "EQUALS" }],
  "ComplianceStatus": [{ "Value": "FAILED", "Comparison": "EQUALS" }]
}
JSON
run aws securityhub get-findings --filters "file://$FILTER" --max-results 10 --region "$REGION" --no-cli-pager

run aws ec2 revoke-security-group-ingress \
  --group-id "$SG_ID" \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0 \
  --region "$REGION" \
  --no-cli-pager

run aws ec2 describe-security-groups --group-ids "$SG_ID" --region "$REGION" --no-cli-pager
run aws ec2 delete-security-group --group-id "$SG_ID" --region "$REGION" --no-cli-pager
run aws ec2 describe-security-groups --group-ids "$SG_ID" --region "$REGION" --no-cli-pager || true
rm -f "$FILTER"
}

demo_s3() {
  print_header "Remediation 2: S3 public -> private"
  if [ "$EXECUTE" -eq 0 ]; then
    cat <<'EOF'
export AWS_PAGER=""
REGION="us-east-1"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text --no-cli-pager)"
BUCKET="acs-baseline-demo-public-$ACCOUNT_ID"

aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" --no-cli-pager

aws s3api put-public-access-block \
  --bucket "$BUCKET" \
  --public-access-block-configuration BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false \
  --region "$REGION" \
  --no-cli-pager

cat > /tmp/demo-public-bucket-policy.json <<JSON
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
JSON

aws s3api put-bucket-policy \
  --bucket "$BUCKET" \
  --policy file:///tmp/demo-public-bucket-policy.json \
  --region "$REGION" \
  --no-cli-pager

aws s3api get-public-access-block --bucket "$BUCKET" --region "$REGION" --no-cli-pager
aws s3api get-bucket-policy-status --bucket "$BUCKET" --region "$REGION" --no-cli-pager
aws s3api get-bucket-policy --bucket "$BUCKET" --region "$REGION" --no-cli-pager

aws s3api delete-bucket-policy --bucket "$BUCKET" --region "$REGION" --no-cli-pager

aws s3api put-public-access-block \
  --bucket "$BUCKET" \
  --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true \
  --region "$REGION" \
  --no-cli-pager

aws s3api get-public-access-block --bucket "$BUCKET" --region "$REGION" --no-cli-pager
aws s3api get-bucket-policy-status --bucket "$BUCKET" --region "$REGION" --no-cli-pager

aws s3 rm "s3://$BUCKET" --recursive --region "$REGION" --no-cli-pager
aws s3api delete-bucket --bucket "$BUCKET" --region "$REGION" --no-cli-pager
aws s3api head-bucket --bucket "$BUCKET" --region "$REGION" --no-cli-pager
EOF
    return
  fi

require_tools aws
export AWS_PAGER=""
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text --no-cli-pager)"
BUCKET="acs-baseline-demo-public-$ACCOUNT_ID"

run aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" --no-cli-pager
run aws s3api put-public-access-block --bucket "$BUCKET" \
  --public-access-block-configuration BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false \
  --region "$REGION" --no-cli-pager

POLICY="$(mktemp)"
cat > "$POLICY" <<JSON
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
JSON

run aws s3api put-bucket-policy --bucket "$BUCKET" --policy "file://$POLICY" --region "$REGION" --no-cli-pager
run aws s3api get-public-access-block --bucket "$BUCKET" --region "$REGION" --no-cli-pager
run aws s3api get-bucket-policy-status --bucket "$BUCKET" --region "$REGION" --no-cli-pager
run aws s3api get-bucket-policy --bucket "$BUCKET" --region "$REGION" --no-cli-pager

run aws s3api delete-bucket-policy --bucket "$BUCKET" --region "$REGION" --no-cli-pager
run aws s3api put-public-access-block --bucket "$BUCKET" \
  --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true \
  --region "$REGION" --no-cli-pager

run aws s3api get-public-access-block --bucket "$BUCKET" --region "$REGION" --no-cli-pager
run aws s3api get-bucket-policy-status --bucket "$BUCKET" --region "$REGION" --no-cli-pager || true

run aws s3 rm "s3://$BUCKET" --recursive --region "$REGION" --no-cli-pager || true
run aws s3api delete-bucket --bucket "$BUCKET" --region "$REGION" --no-cli-pager || true
run aws s3api head-bucket --bucket "$BUCKET" --region "$REGION" --no-cli-pager || true

rm -f "$POLICY"
}

demo_iam() {
  print_header "Remediation 3: IAM wildcard -> least privilege"
  if [ "$EXECUTE" -eq 0 ]; then
    cat <<'EOF'
export AWS_PAGER=""
cd terraform
FIXED_POLICY_ARN="$(terraform output -raw fixed_policy_arn)"
BAD_POLICY_ARN="$(terraform output -raw bad_policy_arn)"
cd ..

# If bad_policy_arn is empty/null, enable the demo-only policy and apply:
#   cd terraform
#   terraform apply -var="create_bad_policy_example=true"
#   terraform output -raw bad_policy_arn

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text --no-cli-pager)"
ROLE="acs-baseline-demo-bad-iam-$(date +%Y%m%d%H%M%S)"

cat > /tmp/trust-demo-role.json <<JSON
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
JSON

aws iam create-role --role-name "$ROLE" --assume-role-policy-document file:///tmp/trust-demo-role.json --no-cli-pager
aws iam attach-role-policy --role-name "$ROLE" --policy-arn "$BAD_POLICY_ARN" --no-cli-pager

aws iam list-attached-role-policies --role-name "$ROLE" --no-cli-pager
aws iam get-policy-version --policy-arn "$BAD_POLICY_ARN" --version-id v1 --no-cli-pager

aws iam detach-role-policy --role-name "$ROLE" --policy-arn "$BAD_POLICY_ARN" --no-cli-pager
aws iam attach-role-policy --role-name "$ROLE" --policy-arn "$FIXED_POLICY_ARN" --no-cli-pager

aws iam list-attached-role-policies --role-name "$ROLE" --no-cli-pager
aws iam get-policy-version --policy-arn "$FIXED_POLICY_ARN" --version-id v1 --no-cli-pager

aws iam detach-role-policy --role-name "$ROLE" --policy-arn "$FIXED_POLICY_ARN" --no-cli-pager
aws iam delete-role --role-name "$ROLE" --no-cli-pager
aws iam get-role --role-name "$ROLE" --no-cli-pager
EOF
    return
  fi

require_tools aws terraform
export AWS_PAGER=""

FIXED_POLICY_ARN="$(tf_output fixed_policy_arn)"
BAD_POLICY_ARN="$(tf_output bad_policy_arn)"
if [ -z "$BAD_POLICY_ARN" ]; then
  echo "bad_policy_arn is empty/null. Run: cd terraform && terraform apply -var=\"create_bad_policy_example=true\"" >&2
  exit 1
fi

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text --no-cli-pager)"
ROLE="acs-baseline-demo-bad-iam-$(date +%Y%m%d%H%M%S)"

TRUST="$(mktemp)"
cat > "$TRUST" <<JSON
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
JSON

run aws iam create-role --role-name "$ROLE" --assume-role-policy-document "file://$TRUST" --no-cli-pager
run aws iam attach-role-policy --role-name "$ROLE" --policy-arn "$BAD_POLICY_ARN" --no-cli-pager
run aws iam list-attached-role-policies --role-name "$ROLE" --no-cli-pager
run aws iam get-policy-version --policy-arn "$BAD_POLICY_ARN" --version-id v1 --no-cli-pager

run aws iam detach-role-policy --role-name "$ROLE" --policy-arn "$BAD_POLICY_ARN" --no-cli-pager
run aws iam attach-role-policy --role-name "$ROLE" --policy-arn "$FIXED_POLICY_ARN" --no-cli-pager
run aws iam list-attached-role-policies --role-name "$ROLE" --no-cli-pager
run aws iam get-policy-version --policy-arn "$FIXED_POLICY_ARN" --version-id v1 --no-cli-pager

run aws iam detach-role-policy --role-name "$ROLE" --policy-arn "$FIXED_POLICY_ARN" --no-cli-pager
run aws iam delete-role --role-name "$ROLE" --no-cli-pager
run aws iam get-role --role-name "$ROLE" --no-cli-pager || true

rm -f "$TRUST"
}

demo_guardduty() {
  print_header "Detection fallback: GuardDuty sample findings -> Security Hub ingestion"
  if [ "$EXECUTE" -eq 0 ]; then
    cat <<'EOF'
export AWS_PAGER=""
cd terraform
DETECTOR_ID="$(terraform output -raw guardduty_detector_id)"
cd ..

aws guardduty create-sample-findings --detector-id "$DETECTOR_ID" --no-cli-pager

cat > /tmp/filters-guardduty.json <<JSON
{
  "ProductName": [
    { "Value": "GuardDuty", "Comparison": "EQUALS" }
  ]
}
JSON

aws securityhub get-findings \
  --filters file:///tmp/filters-guardduty.json \
  --max-results 5 \
  --region us-east-1 \
  --no-cli-pager
EOF
    return
  fi

require_tools aws terraform
export AWS_PAGER=""
DETECTOR_ID="$(tf_output guardduty_detector_id)"
run aws guardduty create-sample-findings --detector-id "$DETECTOR_ID" --no-cli-pager

FILTER="$(mktemp)"
cat > "$FILTER" <<JSON
{
  "ProductName": [
    { "Value": "GuardDuty", "Comparison": "EQUALS" }
  ]
}
JSON
run aws securityhub get-findings --filters "file://$FILTER" --max-results 5 --region "$REGION" --no-cli-pager
rm -f "$FILTER"
}

case "$DEMO" in
  sg) demo_sg ;;
  s3) demo_s3 ;;
  iam) demo_iam ;;
  guardduty) demo_guardduty ;;
  all)
    demo_sg
    demo_s3
    demo_iam
    demo_guardduty
    ;;
  *)
    echo "Invalid --demo: $DEMO (expected sg|s3|iam|guardduty|all)" >&2
    exit 2
    ;;
esac
