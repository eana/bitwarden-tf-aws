terraform {
  backend "s3" {
    profile = "aws-profile"
    region  = "eu-west-1"
    bucket  = "aws-infra-tf"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 3.63.0"
    }
  }
}
