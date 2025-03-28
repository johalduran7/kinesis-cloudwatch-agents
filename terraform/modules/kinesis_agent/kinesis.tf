resource "aws_kinesis_firehose_delivery_stream" "kinesis_firehose" {
  name        = var.firehose_name
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn           = aws_iam_role.firehose_role.arn
    bucket_arn         = aws_s3_bucket.log_bucket.arn
    buffering_size     = 64  #MB
    buffering_interval = 60 # whatever data is in firehose, will be flushed to S3 after this time.
    compression_format = "UNCOMPRESSED"
    #prefix             = ""
    #default#prefix = "logs/!{timestamp:yyyy}/!{timestamp:MM}/!{timestamp:dd}/!{timestamp:HH}/" # only      UTC

    prefix = "logs/!{partitionKeyFromQuery:log_type}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
    error_output_prefix = "logs/errors/"

    dynamic_partitioning_configuration {
      enabled = true
    }
    processing_configuration {
      enabled = true
      processors {
        type = "MetadataExtraction"
        parameters {
          parameter_name  = "JsonParsingEngine"
          parameter_value = "JQ-1.6"
        }
        parameters {
          parameter_name  = "MetadataExtractionQuery"
          parameter_value = "{log_type:.log_type}"
        }
      }
    }

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
