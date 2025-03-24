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
