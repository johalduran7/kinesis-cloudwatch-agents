resource "aws_kinesis_firehose_delivery_stream" "kinesis_firehose" {
  name        = "ec2-logs-stream"
  destination = "s3"

  s3_configuration {
    role_arn           = aws_iam_role.ec2_role.arn
    bucket_arn         = "arn:aws:s3:::my-log-bucket"
    buffering_interval = 300
    compression_format = "GZIP"
  }

  tags = {
    Terraform        = "yes"
    Project = var.tag_allocation_name_cw_agent
  }
}