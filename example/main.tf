provider "aws" {
  region = "eu-west-1"
}

terraform {
  required_version = ">= 0.13.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.56.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 1.4"
    }
  }
}

data "local_file" "this" {
  filename = "${path.module}/env.enc"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.0"

  name = "${var.environment}-vpc"
  cidr = var.cidr[var.environment]

  azs             = var.azs[var.environment]
  public_subnets  = var.public_subnets[var.environment]
  private_subnets = var.private_subnets[var.environment]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  enable_dns_hostnames = true
}

module "bitwarden" {
  source       = "../"
  name         = "bitwarden"
  domain       = "bitwarden.example.org"
  environment  = var.environment
  route53_zone = "example.org."
  ssh_cidr     = ["212.178.73.60/32"]
  env_file     = data.local_file.this.content

  depends_on = [module.vpc]
}
