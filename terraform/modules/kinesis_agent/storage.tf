resource "aws_s3_bucket" "log_bucket" {
  bucket = "${var.s3_bucket_name}-${random_integer.suffix.result}"
  force_destroy=true
  tags = {
    Terraform = "yes"
    Project   = var.tag_allocation_name_kinesis_agent
  }
}

# resource "aws_s3_bucket_acl" "bucket_acl" {
#   bucket = aws_s3_bucket.log_bucket.id
#   acl    = "private"
# }


# resource "aws_glue_crawler" "log_crawler" {
#   name          = "ec2-log-crawler"
#   role          = aws_iam_role.ec2_role.arn
#   database_name = "log_db"
#   s3_target {
#     path = "s3://${aws_s3_bucket.log_bucket.id}/"
#   }
#   tags = {
#     Terraform = "yes"
#     Project   = var.tag_allocation_name_kinesis_agent
#   }
# }

resource "aws_athena_database" "athena_db" {
  name   = "log_analysis_db"
  bucket = aws_s3_bucket.log_bucket.id
}

resource "aws_athena_named_query" "create_table" {
  name        = "create_log_table"
  database    = aws_athena_database.athena_db.name
  description = "Create table for Firehose logs"
  query       = <<EOF
CREATE EXTERNAL TABLE IF NOT EXISTS log_analysis_db.firehose_logs (
  LogType STRING,
  message STRING
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
LOCATION 's3://${aws_s3_bucket.log_bucket.id}/'
TBLPROPERTIES ('has_encrypted_data'='false');
EOF
}
