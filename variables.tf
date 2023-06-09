### VPC ###
variable "enable_vpc" {
  default     = false
  description = "Should be true if you want to provision a VPC and the other network resources"
  type        = bool
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

### DNS ###
variable "enable_route53" {
  default     = false
  description = "Should be true if you want to create the DNS record"
  type        = bool
}

### BITWARDEN ###
variable "name" {
  description = "Name to be used as identifier"
  type        = string
  default     = "bitwarden"
}

variable "environment" {
  description = "The environment to deploy to"
  type        = string
}

variable "tags" {
  description = "Tags applied to resources created with this module"
  type        = map(any)
  default     = {}
}

variable "bucket_version_expiration_days" {
  description = "Specifies when noncurrent object versions expire"
  type        = number
  default     = 30
}

variable "domain" {
  description = "The domain name for the Bitwarden instance"
  type        = string
}

variable "route53_zone" {
  description = "The zone in which the DNS record will be created"
  type        = string
}

variable "ssh_cidr" {
  description = "The IP ranges from where the SSH connections will be allowed"
  type        = list(any)
  default     = []
}

variable "backup_schedule" {
  description = "A cron expression to describe how often your data is backed up"
  type        = string
  default     = "0 9 * * *"
}

variable "additional_tags" {
  description = "Additional tags to apply to resources created with this module"
  type        = map(string)
  default     = {}
}

variable "env_file" {
  description = "The name of the default docker-compose encrypted env file"
  type        = string
}

variable "instance_types" {
  description = "Instance types in the Launch Template. The first instance in the list will have the "
  type        = list(string)
  default     = ["t2.micro", "t2.small"]
}
