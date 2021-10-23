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
