resource "aws_security_group" "main" {
  name        = var.name
  vpc_id      = var.vpc_id

  # Outbound rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "main" {
  count             = length(var.rules_cidr)
  type              = "ingress"
  from_port         = lookup(var.rules_cidr[count.index], "from")
  to_port           = lookup(var.rules_cidr[count.index], "to")
  protocol          = lookup(var.rules_cidr[count.index], "protocol", "tcp")
  cidr_blocks       = lookup(var.rules_cidr[count.index], "cidr")
  security_group_id = aws_security_group.main.id
  depends_on        = [aws_security_group.main]
}

resource "aws_security_group_rule" "sggroup" {
  count                    = length(var.rules_sgsource)
  type                     = "ingress"
  from_port                = lookup(var.rules_sgsource[count.index], "from")
  to_port                  = lookup(var.rules_sgsource[count.index], "to")
  protocol                 = lookup(var.rules_sgsource[count.index], "protocol", "tcp")
  source_security_group_id = lookup(var.rules_sgsource[count.index], "sgid")
  security_group_id        = aws_security_group.main.id
  depends_on               = [aws_security_group.main]
}