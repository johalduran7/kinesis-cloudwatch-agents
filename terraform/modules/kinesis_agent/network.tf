data "aws_subnets" "az_a_subnets" {
  filter {
    name   = "availability-zone"
    values = ["${var.aws_region}a"] # Change this to your desired AZ
  }
}

data "aws_subnet" "selected_subnet" {
  id = tolist(data.aws_subnets.az_a_subnets.ids)[0]
}


resource "aws_security_group" "sg_web" {
  name        = "sg_web"
  description = "allow 80"
  tags = {
    Terraform = "yes"
    Project      = var.tag_allocation_name_cw_agent
  }
}

resource "aws_security_group_rule" "sg_web" {
  type              = "ingress"
  to_port           = "80"
  from_port         = "80"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg_web.id
}

resource "aws_security_group" "sg_ssh" {

  name = "sg_ssh"
  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = "${var.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "sg_ssh"
    Terraform = "yes"
    aws_saa   = "yes"
  }
}
