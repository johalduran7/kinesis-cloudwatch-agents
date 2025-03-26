resource "aws_s3_bucket" "log_bucket" {
  bucket = "my-log-bucket"
}

resource "aws_glue_crawler" "log_crawler" {
  name          = "ec2-log-crawler"
  role          = aws_iam_role.ec2_role.arn
  database_name = "log_db"
  s3_target {
    path = "s3://my-log-bucket/"
  }
}

resource "aws_athena_database" "athena_db" {
  name   = "log_analysis_db"
  bucket = aws_s3_bucket.log_bucket.id
}