data "aws_caller_identity" "current" {}

locals {
  config_bucket_name = lower("${var.name_prefix}-${data.aws_caller_identity.current.account_id}-config-archive")
}

# Service-linked role for AWS Config
resource "aws_iam_service_linked_role" "config" {
  aws_service_name = "config.amazonaws.com"
}

# Dedicated S3 bucket for AWS Config snapshots/history (hardened)
resource "aws_s3_bucket" "config_archive" {
  bucket = local.config_bucket_name
}

resource "aws_s3_bucket_public_access_block" "config_archive" {
  bucket                  = aws_s3_bucket.config_archive.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "config_archive" {
  bucket = aws_s3_bucket.config_archive.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config_archive" {
  bucket = aws_s3_bucket.config_archive.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

# Allow AWS Config to write to this bucket
resource "aws_s3_bucket_policy" "config_write" {
  bucket = aws_s3_bucket.config_archive.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AWSConfigBucketPermissionsCheck",
        Effect    = "Allow",
        Principal = { Service = "config.amazonaws.com" },
        Action    = "s3:GetBucketAcl",
        Resource  = aws_s3_bucket.config_archive.arn
      },
      {
        Sid       = "AWSConfigBucketDelivery",
        Effect    = "Allow",
        Principal = { Service = "config.amazonaws.com" },
        Action    = "s3:PutObject",
        Resource  = "${aws_s3_bucket.config_archive.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/Config/*",
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      }
    ]
  })
}

# Recorder: record all supported resources (incl global)
resource "aws_config_configuration_recorder" "main" {
  name     = "${var.name_prefix}-config-recorder"
  role_arn = aws_iam_service_linked_role.config.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "main" {
  name           = "${var.name_prefix}-config-delivery"
  s3_bucket_name = aws_s3_bucket.config_archive.bucket

  depends_on = [
    aws_config_configuration_recorder.main,
    aws_s3_bucket_policy.config_write
  ]
}

# Start recording (this is what Security Hub needs)
resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.main]
}
