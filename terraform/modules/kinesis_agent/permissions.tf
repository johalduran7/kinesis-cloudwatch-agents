
# EC2 roles and policies to allow it to write to Firehose and CW
resource "aws_iam_role" "ec2_role" {
  name = "EC2KinesisRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "ec2_kinesis_policy" {
  name        = "EC2KinesisPolicy"
  description = "Policy to allow EC2 to send logs to Kinesis Data Firehose"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "firehose:PutRecord",
        "firehose:PutRecordBatch"
      ],
      "Resource": "${aws_kinesis_firehose_delivery_stream.kinesis_firehose.arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams",
        "logs:CreateLogStream"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}


resource "aws_iam_policy" "cloudwatch_log_policy_kinesis_agent" {
  name = "cloudwatch-log-policy-kinesis-agent"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
          "logs:PutLogEvents",
          "ec2:DescribeTags",
          "cloudwatch:PutMetricData"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_policy_kinesis_agent_cloudwatch" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.cloudwatch_log_policy_kinesis_agent.arn
}

resource "aws_iam_role_policy_attachment" "attach_policy_kinesis_agent_kdf_s3" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_kinesis_policy.arn
}


resource "aws_iam_instance_profile" "ec2_kinesis_instance_profile" {
  name = "EC2InstanceProfile"
  role = aws_iam_role.ec2_role.name
}



# Firehose roles and policies to be able to write to S3
resource "aws_iam_role" "firehose_role" {
  name = "FirehoseRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "firehose_s3_policy" {
  name        = "FirehoseS3Policy"
  description = "Policy to allow Firehose to write logs to S3"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "${aws_s3_bucket.log_bucket.arn}",
        "${aws_s3_bucket.log_bucket.arn}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "firehose_s3_attach" {
  role       = aws_iam_role.firehose_role.name
  policy_arn = aws_iam_policy.firehose_s3_policy.arn
}

resource "aws_iam_policy" "firehose_cloudwatch_policy" {
  name        = "FirehoseCloudWatchPolicy"
  description = "Policy to allow Firehose to write logs to CloudWatch"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:PutLogEvents",
        "logs:DescribeLogStreams",
        "logs:DescribeLogGroups",
        "logs:CreateLogStream",
        "logs:CreateLogGroup"
      ],
      "Resource": "${aws_kinesis_firehose_delivery_stream.kinesis_firehose.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "firehose_cloudwatch_attach" {
  role       = aws_iam_role.firehose_role.name
  policy_arn = aws_iam_policy.firehose_cloudwatch_policy.arn
}


# S3 Bucket policy to allow Firehose to send events to the bucket:
resource "aws_s3_bucket_policy" "firehose_s3_policy" {
  bucket = aws_s3_bucket.log_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = { "Service": "firehose.amazonaws.com" }
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.log_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = "${data.aws_caller_identity.current.account_id}"
          }
          ArnLike = {
            "aws:SourceArn" = "${aws_kinesis_firehose_delivery_stream.kinesis_firehose.arn}"
          }
        }
      }
    ]
  })
}

data "aws_caller_identity" "current" {}


# Glue crawler policy
resource "aws_iam_role" "glue_crawler_role" {
  name = "AWSGlueServiceRole-ec2-kinesis"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "ec2_kinesis_s3_policy" {
  name        = "AWSGlueServiceRole-ec2-kinesis-EZCRC-s3Policy"
  description = "Policy for ec2 kinesis s3 access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ],
        Resource = [
          "${aws_s3_bucket.log_bucket.arn}",
          "${aws_s3_bucket.log_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "glue_crawler_policy_attachment" {
  role       = aws_iam_role.glue_crawler_role.name
  policy_arn = aws_iam_policy.ec2_kinesis_s3_policy.arn
}

resource "aws_iam_role_policy_attachment" "glue_service_role_attachment" {
  role       = aws_iam_role.glue_crawler_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}