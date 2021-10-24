variable "name" {
  description = "Name to be used  as identifier"
  type        = string
  default     = "bitwarden"
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

variable "kms_key_alias" {
  description = "The alias for the KMS customer master key which the data/env.enc file was encrypted with."
  default     = "alias/bitwarden-sops-encryption-key-prod"
}
