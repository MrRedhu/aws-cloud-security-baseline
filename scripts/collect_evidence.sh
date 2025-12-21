#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${ROOT_DIR}/terraform"

echo "AWS Cloud Security Baseline - Evidence Command Helper"
echo

echo "Prereqs:"
echo "  - Authenticate AWS CLI (and set AWS_PAGER=\"\"), then run from repo root."
echo "  - Ensure Terraform has been applied at least once (terraform output available)."
echo

cat <<'EOF'
--- Terraform outputs (names/ARNs) ---
cd terraform
terraform output

--- Step 3 (IAM) ---
aws sts get-caller-identity --no-cli-pager
aws iam list-attached-role-policies --role-name acs-baseline-developer-role --no-cli-pager
aws iam get-policy-version --policy-arn <BAD_POLICY_ARN> --version-id v1 --no-cli-pager
aws iam get-policy-version --policy-arn <FIXED_POLICY_ARN> --version-id v1 --no-cli-pager

--- Step 4 (Logging) ---
aws s3api get-public-access-block --bucket <LOG_BUCKET> --no-cli-pager
aws s3api get-bucket-ownership-controls --bucket <LOG_BUCKET> --no-cli-pager
aws s3api get-bucket-encryption --bucket <LOG_BUCKET> --no-cli-pager
aws s3api get-bucket-versioning --bucket <LOG_BUCKET> --no-cli-pager
aws s3api get-bucket-policy --bucket <LOG_BUCKET> --no-cli-pager
aws cloudtrail describe-trails --no-cli-pager
aws cloudtrail get-trail-status --name <TRAIL_NAME> --no-cli-pager
aws logs describe-log-groups --log-group-name-prefix /aws/cloudtrail/acs-baseline --no-cli-pager
aws ec2 describe-flow-logs --no-cli-pager
aws logs describe-log-groups --log-group-name-prefix /aws/vpc/flowlogs/acs-baseline --no-cli-pager

--- Step 5 (Detection + Config) ---
aws guardduty list-detectors --no-cli-pager
aws guardduty get-detector --detector-id <DETECTOR_ID> --no-cli-pager
aws securityhub describe-hub --no-cli-pager
aws securityhub get-enabled-standards --no-cli-pager
aws configservice describe-configuration-recorder-status --no-cli-pager
aws configservice describe-configuration-recorders --no-cli-pager
aws configservice describe-delivery-channels --no-cli-pager
aws s3api get-public-access-block --bucket <CONFIG_BUCKET> --no-cli-pager
aws s3api get-bucket-ownership-controls --bucket <CONFIG_BUCKET> --no-cli-pager
aws s3api get-bucket-encryption --bucket <CONFIG_BUCKET> --no-cli-pager
aws s3api get-bucket-versioning --bucket <CONFIG_BUCKET> --no-cli-pager
aws s3api get-bucket-policy --bucket <CONFIG_BUCKET> --no-cli-pager

--- Step 6/7 (Remediations) ---
# SG demo (open SSH -> fixed): see evidence/04-remediation-1-sg-open.md
# S3 demo (public -> private): see evidence/05-remediation-2-s3-public.md
# IAM demo (wildcard -> fixed): see evidence/06-remediation-3-iam-wildcards.md
EOF

if command -v terraform >/dev/null 2>&1 && [ -d "${TF_DIR}" ]; then
  if (cd "${TF_DIR}" && terraform output >/dev/null 2>&1); then
    LOG_BUCKET="$(cd "${TF_DIR}" && terraform output -raw log_bucket_name 2>/dev/null || true)"
    CONFIG_BUCKET="$(cd "${TF_DIR}" && terraform output -raw config_bucket_name 2>/dev/null || true)"
    TRAIL_NAME="$(cd "${TF_DIR}" && terraform output -raw cloudtrail_name 2>/dev/null || true)"
    BAD_POLICY_ARN="$(cd "${TF_DIR}" && terraform output -raw bad_policy_arn 2>/dev/null || true)"
    FIXED_POLICY_ARN="$(cd "${TF_DIR}" && terraform output -raw fixed_policy_arn 2>/dev/null || true)"
    DETECTOR_ID="$(cd "${TF_DIR}" && terraform output -raw guardduty_detector_id 2>/dev/null || true)"

    echo
    echo "--- Resolved placeholders (from terraform output) ---"
    [ -n "${LOG_BUCKET}" ] && echo "LOG_BUCKET=${LOG_BUCKET}"
    [ -n "${CONFIG_BUCKET}" ] && echo "CONFIG_BUCKET=${CONFIG_BUCKET}"
    [ -n "${TRAIL_NAME}" ] && echo "TRAIL_NAME=${TRAIL_NAME}"
    [ -n "${BAD_POLICY_ARN}" ] && echo "BAD_POLICY_ARN=${BAD_POLICY_ARN}"
    [ -n "${FIXED_POLICY_ARN}" ] && echo "FIXED_POLICY_ARN=${FIXED_POLICY_ARN}"
    [ -n "${DETECTOR_ID}" ] && echo "DETECTOR_ID=${DETECTOR_ID}"
  fi
fi
