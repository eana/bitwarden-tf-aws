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
