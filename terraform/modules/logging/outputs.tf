output "log_bucket_name" {
  value = aws_s3_bucket.log_archive.bucket
}

output "cloudtrail_name" {
  value = aws_cloudtrail.main.name
}

output "cloudtrail_log_group" {
  value = aws_cloudwatch_log_group.cloudtrail.name
}

output "vpc_flow_log_group" {
  value = aws_cloudwatch_log_group.vpc_flowlogs.name
}

output "flowlogs_vpc_id" {
  value = aws_vpc.flowlogs_vpc.id
}
