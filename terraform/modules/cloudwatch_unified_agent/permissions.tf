resource "aws_iam_role" "ec2_cloudwatch_role" {
  name = "ec2-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for Logging Permissions
#note: "ec2:DescribeTags" this one is needed for CW Agent to run
resource "aws_iam_policy" "cloudwatch_log_policy_agent" {
  name = "cloudwatch-log-policy-agent"

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

# Attach IAM Policy to Role
resource "aws_iam_role_policy_attachment" "attach_policy_cw_agent" {
  role       = aws_iam_role.ec2_cloudwatch_role.name
  policy_arn = aws_iam_policy.cloudwatch_log_policy_agent.arn
}

resource "aws_iam_instance_profile" "ec2_cw_instance_profile" {
  name = "ec2-cw-instance-profile"
  role = aws_iam_role.ec2_cloudwatch_role.name
}