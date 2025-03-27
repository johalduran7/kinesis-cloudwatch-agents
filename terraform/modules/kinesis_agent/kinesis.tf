resource "aws_kinesis_firehose_delivery_stream" "kinesis_firehose" {
  name        = var.firehose_name
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn           = aws_iam_role.firehose_role.arn
    bucket_arn         = aws_s3_bucket.log_bucket.arn
    buffering_size     = 1  #MB
    buffering_interval = 60 # whatever data is in firehose, will be flushed to S3 after this time.
    compression_format = "GZIP"
    prefix             = ""

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose_log_group.name
      log_stream_name = aws_cloudwatch_log_stream.firehose_log_stream.name
    }
  }


  tags = {
    Terraform = "yes"
    Project   = var.tag_allocation_name_kinesis_agent
  }
}
