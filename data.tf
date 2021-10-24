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
  filter {
    name   = "tag:Name"
    values = ["${terraform.workspace}-vpc"]
  }
}

data "aws_subnets" "this" {
  filter {
    name   = "tag:Name"
    values = ["${terraform.workspace}-vpc-public-${local.az}"]
  }
}

data "aws_route53_zone" "this" {
  name         = var.route53_zone
  private_zone = false
}

data "aws_kms_key" "this" {
  key_id = var.kms_key_alias
}

data "local_file" "this" {
  filename = "${path.module}/data/env.enc"
}