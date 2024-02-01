resource "aws_security_group" "this" {
  name        = var.name
  vpc_id      = data.aws_vpc.this.id
  description = "Security group for EC2 instance ${var.name}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_cidr
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.default_tags
}

resource "aws_network_interface" "this" {
  security_groups   = [aws_security_group.this.id]
  subnet_id         = data.aws_subnets.this.ids[0]
  source_dest_check = false
  description       = "ENI for EC2 instance ${var.name}"
  tags              = local.default_tags
}

resource "aws_eip" "this" {
  network_interface = aws_network_interface.this.id
  tags              = local.default_tags
}

resource "aws_route53_record" "this" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = var.domain
  type    = "A"
  ttl     = "300"
  records = [aws_eip.this.public_ip]
}
