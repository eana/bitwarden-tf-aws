module "vpc" {
  count = var.enable_vpc ? 1 : 0

  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "${terraform.workspace}-vpc"
  cidr = var.cidr[terraform.workspace]

  azs             = var.azs[terraform.workspace]
  public_subnets  = var.public_subnets[terraform.workspace]
  private_subnets = var.private_subnets[terraform.workspace]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  enable_dns_hostnames = true
}

resource "aws_security_group" "this" {
  name        = var.name
  vpc_id      = var.enable_vpc ? module.vpc.vpc_id : data.aws_vpc.this[0].id
  description = "Security group for EC2 instance ${var.name}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:AWS009
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_cidr
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:AWS008
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:AWS008
  }

  tags = local.default_tags
}

resource "aws_network_interface" "this" {
  security_groups   = [aws_security_group.this.id]
  subnet_id         = var.enable_vpc ? module.vpc.public_subnets[0] : data.aws_subnets.this[0].ids[0]
  source_dest_check = false
  description       = "ENI for EC2 instance ${var.name}"
  tags              = local.default_tags
}

resource "aws_eip" "this" {
  network_interface = aws_network_interface.this.id
  tags              = local.default_tags
}

resource "aws_route53_record" "this" {
  count = var.enable_route53 ? 1 : 0

  zone_id = data.aws_route53_zone.this[0].zone_id
  name    = var.domain
  type    = "A"
  ttl     = "300"
  records = [aws_eip.this.public_ip]
}
