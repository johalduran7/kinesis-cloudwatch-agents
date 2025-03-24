# EC2 Instance  -- Exporting files to CW using AWS CW Unified. Unified Agent: If the version is 1.247.0.0 or newer, you have the Unified Agent.
# The Agent legacy version works the same way, same commands.
# this instance adds logs to the same loggroup as the logs_daemon, this is just to test both types of cloudwatch producers. 

# Create the SSH pair key: ssh-keygen -t rsa -b 4096 -f key_saa -N ""
resource "aws_key_pair" "ssh_key" {
  key_name   = "ssh-key"
  public_key = file("ssh_key.pub")
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"] # Amazon's official AMI owner ID

  filter {
    name   = "name"
    values = ["al2023-ami-2023.6.20250128.0-kernel-6.1-x86_64"] # Amazon Linux 2 AMI
    #values = ["Amazon Linux 2023 AMI"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "random_integer" "suffix" {
  min = 1000
  max = 1999
}

resource "aws_instance" "ec2_cw_agent" {
  ami                    = data.aws_ami.amazon_linux.id
  key_name               = aws_key_pair.ssh_key.key_name
  instance_type          = "t2.micro"
  subnet_id              = data.aws_subnet.selected_subnet.id
  vpc_security_group_ids = [aws_security_group.sg_ssh.id, aws_security_group.sg_web.id]

  # User Data to Configure CloudWatch Agent and Generate Logs.
  # if the EC2 role has permissions to create loggroups, you don't even have to create them using terraform
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y amazon-cloudwatch-agent

    yum install -y amazon-cloudwatch-agent httpd
    # Start Apache Server
    systemctl start httpd
    systemctl enable httpd
    echo "Hello World from Apache running on $(curl http://169.254.169.254/latest/meta-data/instance-id) " > /var/www/html/index.html

    # Configure Apache to log in JSON format


    echo 'LogFormat "{   \"LogType\": \"access\",   \"time\": \"%%{%Y-%m-%dT%H:%M:%S%z}t\",   \"remote_ip\": \"%a\",   \"host\": \"%v\",   \"method\": \"%m\",   \"url\": \"%U\",   \"query\": \"%q\",   \"protocol\": \"%H\",   \"status\": \"%>s\",   \"bytes_sent\": \"%B\",   \"referer\": \"%%{Referer}i\",   \"user_agent\": \"%%{User-Agent}i\",   \"response_time_microseconds\": \"%D\",   \"forwarded_for\": \"%%{X-Forwarded-For}i\",   \"http_version\": \"%H\",   \"request\": \"%r\" }" json' > /etc/httpd/conf.d/custom_log_format.conf
    echo 'CustomLog /var/log/httpd/access_log json' >> /etc/httpd/conf.d/custom_log_format.conf


    systemctl restart httpd

  
    # Ensure Apache's access log file exists
    if [ ! -f /var/log/httpd/access_log ]; then
      touch /var/log/httpd/access_log
    fi


    # Set the region in the CloudWatch Agent configuration file
    sed -i 's/region = .*/region = ${var.aws_region}/' /etc/awslogs/awscli.conf

    # Generate Logs Every Minute
    echo "* * * * * root echo '{\"LogType\": \"sample_logs\", \"message\": \"Sample log generated at $(date --iso-8601=seconds)\"} frommm AWS CloudWatch Agent' >> /var/log/sample_logs" >> /etc/cron.d/generate_logs
    chmod 0644 /etc/cron.d/generate_logs

    # Start CloudWatch Agent

    # Create CloudWatch Agent Configuration File in the correct directory
    cat <<EOT > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
    {
        "agent":{
            "run_as_user":"root"
        },
        "logs": {
            "logs_collected": {
            "files": {
                "collect_list": [
                {
                    "file_path": "/var/log/messages",
                    "log_group_name": "${aws_cloudwatch_log_group.ec2_log_group.name}",
                    "log_stream_name": "${aws_cloudwatch_log_stream.ec2_log_stream.name}",
                    "timestamp_format": "%b %d %H:%M:%S.%f"
                },
                {
                    "file_path": "/var/log/sample_logs",
                    "log_group_name": "${aws_cloudwatch_log_group.ec2_log_group.name}",
                    "log_stream_name": "${aws_cloudwatch_log_stream.ec2_log_stream.name}",
                    "timestamp_format": "%b %d %H:%M:%S.%f"
                },
                {
                    "file_path": "/var/log/httpd/access_log",
                    "log_group_name": "${aws_cloudwatch_log_group.ec2_log_group.name}",
                    "log_stream_name": "${aws_cloudwatch_log_stream.ec2_log_stream.name}",
                    "timestamp_format": "%b %d %H:%M:%S.%f"
                }                
                ]
            }
            }
        }
    }

    EOT

    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a start -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
    
  EOF

  iam_instance_profile = aws_iam_instance_profile.ec2_cw_instance_profile.name

  tags = {
    Name         = "ec2_cw-${random_integer.suffix.result}-apache"
    Terraform    = "yes"
    CW_collector = "AWS CloudWatch Agent"
    Apache       = "yes"
    Project      = var.tag_allocation_name_cw_agent
  }
}
