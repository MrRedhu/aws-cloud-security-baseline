data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  # S3 bucket names must be globally unique + lowercase
  log_bucket_name = lower("${var.name_prefix}-${data.aws_caller_identity.current.account_id}-log-archive")
  cloudtrail_name = "${var.name_prefix}-trail"
}

# -----------------------------
# S3: Central hardened log archive bucket
# -----------------------------
resource "aws_s3_bucket" "log_archive" {
  bucket = local.log_bucket_name
}

resource "aws_s3_bucket_public_access_block" "log_archive" {
  bucket                  = aws_s3_bucket.log_archive.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "log_archive" {
  bucket = aws_s3_bucket.log_archive.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log_archive" {
  bucket = aws_s3_bucket.log_archive.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CloudTrail requires permission to write to the bucket
resource "aws_s3_bucket_policy" "cloudtrail_write" {
  bucket = aws_s3_bucket.log_archive.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck",
        Effect    = "Allow",
        Principal = { Service = "cloudtrail.amazonaws.com" },
        Action    = "s3:GetBucketAcl",
        Resource  = aws_s3_bucket.log_archive.arn
      },
      {
        Sid       = "AWSCloudTrailWrite",
        Effect    = "Allow",
        Principal = { Service = "cloudtrail.amazonaws.com" },
        Action    = "s3:PutObject",
        Resource  = "${aws_s3_bucket.log_archive.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      }
    ]
  })
}

# -----------------------------
# CloudWatch Logs: Log group for CloudTrail (with retention)
# -----------------------------
resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/${var.name_prefix}"
  retention_in_days = var.cw_log_retention_days
}

# IAM role CloudTrail uses to write to CloudWatch Logs
resource "aws_iam_role" "cloudtrail_to_cw" {
  name = "${var.name_prefix}-cloudtrail-cw-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "cloudtrail.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "cloudtrail_to_cw" {
  name = "${var.name_prefix}-cloudtrail-cw-policy"
  role = aws_iam_role.cloudtrail_to_cw.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      Resource = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
    }]
  })
}

# -----------------------------
# CloudTrail: org-grade API logging (S3 + CloudWatch)
# -----------------------------
resource "aws_cloudtrail" "main" {
  name                          = local.cloudtrail_name
  s3_bucket_name                = aws_s3_bucket.log_archive.bucket
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_to_cw.arn

  depends_on = [aws_s3_bucket_policy.cloudtrail_write]
}

# -----------------------------
# VPC + Flow Logs (to CloudWatch Logs, with retention)
# -----------------------------
resource "aws_vpc" "flowlogs_vpc" {
  cidr_block           = "10.50.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.name_prefix}-flowlogs-vpc" }
}

resource "aws_cloudwatch_log_group" "vpc_flowlogs" {
  name              = "/aws/vpc/flowlogs/${var.name_prefix}"
  retention_in_days = var.cw_log_retention_days
}

resource "aws_iam_role" "flowlogs_to_cw" {
  name = "${var.name_prefix}-flowlogs-cw-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "vpc-flow-logs.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "flowlogs_to_cw" {
  name = "${var.name_prefix}-flowlogs-cw-policy"
  role = aws_iam_role.flowlogs_to_cw.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      Resource = "${aws_cloudwatch_log_group.vpc_flowlogs.arn}:*"
    }]
  })
}

resource "aws_flow_log" "vpc_flowlogs" {
  vpc_id               = aws_vpc.flowlogs_vpc.id
  traffic_type         = "ALL"
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.vpc_flowlogs.arn
  iam_role_arn         = aws_iam_role.flowlogs_to_cw.arn
}
