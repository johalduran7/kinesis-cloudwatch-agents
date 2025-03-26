
output "public_ip_ec2_apache" {
  value = aws_instance.ec2_kinesis_agent.public_ip
}

output "s3_bucket_name" {
  value = aws_s3_bucket.log_bucket.id
}
