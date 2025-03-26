# CloudWatch Log Group for CloudWatch Logs Daemon, CloudWatch Agent and    Unified
resource "aws_cloudwatch_log_group" "ec2_log_group" {
  name              = "/${var.aws_region}/${var.Component}"
  retention_in_days = 1 # Retain logs for 7 days

}

# CloudWatch Log Stream for CloudWatch Logs Daemon
resource "aws_cloudwatch_log_stream" "ec2_log_stream" {
  name           = "${var.Component}-${random_integer.suffix.result}"
  log_group_name = aws_cloudwatch_log_group.ec2_log_group.name
}