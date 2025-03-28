variable "aws_region" {
  default = ""
}

variable "vpc_id" {
  default = ""
}

variable "tag_allocation_name_cw_agent" {
  default = "CloudWatch_Agent"
}

variable "Component" {
  type    = string
  default = "ec2_cw"
}