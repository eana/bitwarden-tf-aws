### BITWARDEN ###
# AMI of the latest Amazon Linux 2
data "aws_ami" "this" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "block-device-mapping.volume-type"
    values = ["gp2"]
  }
}

data "aws_vpc" "this" {
  count = var.enable_vpc ? 0 : 1

  filter {
    name   = "tag:Name"
    values = ["${var.environment}-vpc"]
  }
}

data "aws_subnets" "this" {
  count = var.enable_vpc ? 0 : 1

  filter {
    name   = "tag:Name"
    values = ["${var.environment}-vpc-public-${local.az}"]
  }
}

data "aws_route53_zone" "this" {
  count        = var.enable_route53 ? 1 : 0
  name         = var.route53_zone
  private_zone = false
}
