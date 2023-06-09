variable "environment" {
  default     = "prod"
  description = "The environment to deploy the app in."
  type        = string
}

variable "cidr" {
  default = {
    "prod" = "10.100.0.0/16"
    "test" = "10.101.0.0/16"
  }
  description = "The CIDR block for the VPC."
  type        = map(string)
}

variable "azs" {
  default = {
    "prod" = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
    "test" = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  }
  description = "List of availability zones/"
  type        = map(list(string))
}

variable "public_subnets" {
  default = {
    "prod" = ["10.100.0.0/20", "10.100.16.0/20", "10.100.32.0/20"]
    "test" = ["10.101.0.0/20", "10.101.16.0/20", "10.101.32.0/20"]
  }
  description = "List of cidr_blocks of public subnets."
  type        = map(list(string))
}

variable "private_subnets" {
  default = {
    "prod" = ["10.100.96.0/20", "10.100.112.0/20", "10.100.128.0/20"]
    "test" = ["10.101.96.0/20", "10.101.112.0/20", "10.101.128.0/20"]
  }
  description = "List of cidr_blocks of private subnets."
  type        = map(list(string))
}
