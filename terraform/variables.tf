variable "aws_region" {
  default = "us-east-1"
}

variable "vpc_id" {
  default = "vpc-53cd6b2e"
}

variable "tag_allocation_name_cw_agent" {
  default = "CloudWatch_Agent"
}

variable "tag_allocation_name_kinesis_agent" {
  default = "Kinesis_Agent"
}

variable "s3_bucket_name" {
  default = "ec2-kinesis-log"
}

variable firehose_name {
  default     = "ec2-logs-stream"
}
