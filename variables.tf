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
