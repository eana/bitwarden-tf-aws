terraform {
  backend "s3" {
    profile = "aws-profile"
    region  = "eu-west-1"
    bucket  = "aws-infra-tf"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "=3.64.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "= 2.1.0"
    }
  }
}
