resource "aws_kinesis_firehose_delivery_stream" "kinesis_firehose" {
  name        = "ec2-logs-stream"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn           = aws_iam_role.ec2_role.arn
    bucket_arn         = var.s3_bucket_name
    buffering_size      = 5 #MB
    buffering_interval = 300 # whatever data is in firehose, will be flushed to S3 after this time.
    compression_format = "GZIP"
    prefix              = ""

  }

  tags = {
    Terraform = "yes"
    Project   = var.tag_allocation_name_kinesis_agent
  }
}