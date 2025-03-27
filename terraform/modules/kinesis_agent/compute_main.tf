resource "aws_key_pair" "ssh_key" {
  key_name   = "ssh-key"
  public_key = file("ssh_key.pub")
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"] # Amazon's official AMI owner ID

  filter {
    name = "name"
    #values = ["al2023-ami-2023.6.20250128.0-kernel-6.1-x86_64"] # Amazon Linux 3 AMI
    values = ["amzn2-ami-hvm-*-x86_64-gp2"] # Amazon Linux 2 AMI
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


resource "aws_instance" "ec2_kinesis_agent" {
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

    #installing cron on Amazon Linux 3
    #yum install -y cronie
    #systemctl start crond


    yum install -y httpd
    # Start Apache Server
    systemctl start httpd
    systemctl enable httpd
    TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" "http://169.254.169.254/latest/meta-data/instance-id")
    echo "Hello World from Apache running on $INSTANCE_ID " > /var/www/html/index.html

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
    echo "* * * * * root echo '{\"LogType\": \"sample_logs\", \"message\": \"Sample log generated at $(TZ="America/Bogota" date --iso-8601=seconds)\"}' >> /var/log/sample_logs" >> /etc/cron.d/generate_logs
    chmod 0644 /etc/cron.d/generate_logs

    # Start CloudWatch Agent
    #  /var/log/messages" is not used anymore because Amazon Linux 2023 uses journal to collect logs. The logs are stored in binary files so they are scrape differently
    # Create CloudWatch Agent Configuration File in the correct directory

    yum install -y aws-kinesis-agent
    systemctl enable aws-kinesis-agent
    cat <<EOT > /etc/aws-kinesis/agent.json
    {
        "cloudwatch.emitMetrics": true,
        "kinesis.endpoint": "https://kinesis.${var.aws_region}.amazonaws.com",
        "firehose.endpoint": "https://firehose.${var.aws_region}.amazonaws.com",
        "flows": [
            {
                "filePattern": "/var/log/sample_logs",
                "deliveryStream": "${var.firehose_name}"
            }
        ]
    }
    EOT

    sudo setfacl -m u:aws-kinesis-agent-user:r /var/log/messages
    sudo setfacl -m u:aws-kinesis-agent-user:r /var/log/sample_logs
    sudo setfacl -m u:aws-kinesis-agent-user:r /var/log/httpd/access_log

    systemctl restart aws-kinesis-agent

  EOF


  iam_instance_profile = aws_iam_instance_profile.ec2_kinesis_instance_profile.name

  tags = {
    Name         = "${var.Component}-${random_integer.suffix.result}-apache"
    Terraform    = "yes"
    CW_collector = "AWS CloudWatch Agent"
    Apache       = "yes"
    Project      = var.tag_allocation_name_kinesis_agent
  }
}



    # cat <<EOT > /etc/aws-kinesis/agent.json
    # {
    #     "cloudwatch.emitMetrics": true,
    #     "kinesis.endpoint": "https://kinesis.${var.aws_region}.amazonaws.com",
    #     "firehose.endpoint": "https://firehose.${var.aws_region}.amazonaws.com",
    #     "flows": [
    #         {
    #             "filePattern": "/var/log/messages",
    #             "deliveryStream": "${var.firehose_name}"
    #         },
    #         {
    #             "filePattern": "/var/log/sample_logs",
    #             "deliveryStream": "${var.firehose_name}"
    #         },
    #         {
    #             "filePattern": "/var/log/httpd/access_log",
    #             "deliveryStream": "${var.firehose_name}"
    #         }
    #     ]
    # }
    # EOT