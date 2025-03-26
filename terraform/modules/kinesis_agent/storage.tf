resource "aws_s3_bucket" "log_bucket" {
  bucket = var.s3_bucket_name
  tags = {
    Terraform        = "yes"
    Project = var.tag_allocation_name_cw_agent
  }
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.log_bucket.id
  acl    = "private"
}


resource "aws_glue_crawler" "log_crawler" {
  name          = "ec2-log-crawler"
  role          = aws_iam_role.ec2_role.arn
  database_name = "log_db"
  s3_target {
    path = "s3://${aws_s3_bucket.log_bucket.id}/"
  }
  tags = {
    Terraform        = "yes"
    Project = var.tag_allocation_name_cw_agent
  }
}

resource "aws_athena_database" "athena_db" {
  name   = "log_analysis_db"
  bucket = aws_s3_bucket.log_bucket.id

}