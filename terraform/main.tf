provider "aws" {
  region = var.aws_region
}

module cloudwatch_unified_agent {
  source = "./modules/cloudwatch_unified_agent"
  aws_region  = var.aws_region
  tag_allocation_name_cw_agent= var.tag_allocation_name_cw_agent
  vpc_id=var.vpc_id
}
