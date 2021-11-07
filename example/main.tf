provider "aws" {
  region = "eu-west-1"
}

terraform {
  required_version = ">= 0.13.1"
}

data "local_file" "this" {
  filename = "${path.module}/env.enc"
}

data "aws_kms_key" "this" {
  key_id = "alias/bitwarden-sops-encryption-key-prod"
}

module "bitwarden" {
  source       = "../"
  name         = "bitwarden"
  domain       = "bitwarden.example.org"
  environment  = "prod"
  route53_zone = "example.org."
  ssh_cidr     = ["212.178.73.60/32"]
  env_file     = data.local_file.this.content
}
