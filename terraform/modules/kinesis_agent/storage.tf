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

resource "aws_athena_database" "athena_db" {
  name   = "log_analysis_db"
  bucket = aws_s3_bucket.log_bucket.id
  force_destroy=true
}

resource "aws_glue_crawler" "log_crawler" {
  name          = "ec2-log-crawler"
  role          = aws_iam_role.glue_crawler_role.arn
  database_name = aws_athena_database.athena_db.name
  s3_target {
    path = "s3://${aws_s3_bucket.log_bucket.id}/"
    exclusions = [
      "athena-results/*"  # Exclude the Athena results folder
    ]
  }
  schedule = "cron(0 * * * ? *)" # Runs hourly at the 0th minute. this is because firehose separate it per hour
  tags = {
    Terraform = "yes"
    Project   = var.tag_allocation_name_kinesis_agent
  }
}


resource "aws_athena_workgroup" "log_analysis_workgroup" {
  name = "log_analysis_workgroup"
  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true
    requester_pays_enabled             = false
    result_configuration {
      output_location = "s3://${aws_s3_bucket.log_bucket.id}/athena-results/"
    }
  }
}

# resource "aws_athena_named_query" "log_query" {
#   name          = "LogQuery"
#   database      = aws_athena_database.log_analysis_db.name
#   workgroup     = aws_athena_workgroup.log_analysis_workgroup.name
#   query_string  = <<EOT
#     CREATE EXTERNAL TABLE IF NOT EXISTS log_analysis_db.sample_logs (
#       logtype STRING,
#       timestamp STRING,
#       message STRING
#     )
#     ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
#     LOCATION 's3://${aws_s3_bucket.log_bucket.id}/logs/'
#     TBLPROPERTIES ('has_encrypted_data'='false');
#   EOT
# }




