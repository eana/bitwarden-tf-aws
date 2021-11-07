provider "aws" {
  region = "eu-west-1"
}

module "bitwarden" {
  source        = "../"
  domain        = "bw.example.org"
  environment   = "prod"
  route53_zone  = "example.org."
  ssh_cidr      = ["212.178.73.60/32"]
  kms_key_alias = "alias/bitwarden-sops-encryption-key-prod"
}
