variable "aws_region" {
  default = ""
}

variable "vpc_id" {
  default = ""
}

variable "tag_allocation_name_kinesis_agent" {
  default = ""
}

variable "Component" {
  type    = string
  default = "ec2_kinesis"
}

variable "s3_bucket_name" {
  default = "ec2_kinesis_log"
}

variable firehose_name {
  default     = "ec2-logs-stream"
}
