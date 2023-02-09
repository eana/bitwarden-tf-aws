provider "aws" {
  region = "eu-west-1"
}

terraform {
  required_version = ">= 0.13.1"

  required_providers {
    aws   = ">= 3.56.0"
    local = ">= 1.4"
  }
}

data "local_file" "this" {
  filename = "${path.module}/env.enc"
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
