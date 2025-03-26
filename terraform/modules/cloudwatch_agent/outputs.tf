
output "public_ip_ec2_apache" {
  value = aws_instance.ec2_cw_agent.public_ip
}
