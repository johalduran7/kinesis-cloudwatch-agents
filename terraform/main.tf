provider "aws" {
  region = var.aws_region
}

# module "cloudwatch_agent" {
#   source                       = "./modules/cloudwatch_agent"
#   aws_region                   = var.aws_region
#   tag_allocation_name_cw_agent = var.tag_allocation_name_cw_agent
#   vpc_id                       = var.vpc_id
# }


module "kinesis_agent" {
  source                            = "./modules/kinesis_agent"
  aws_region                        = var.aws_region
  tag_allocation_name_kinesis_agent = var.tag_allocation_name_kinesis_agent
  vpc_id                            = var.vpc_id
  s3_bucket_name                    = var.s3_bucket_name
  firehose_name                     = var.firehose_name
}
