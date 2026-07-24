variable "aws_region" {
  description = "AWS region. Default eu-north-1 as it tends to be cheaper than other regions for spot instances."
  type        = string
  default     = "eu-north-1"
}

variable "domain" {
  description = "Domain for vaultwarden and Cloudflare DNS"
  type        = string
}

variable "name" {
  description = "Resource name prefix"
  type        = string
  default     = "bitwarden"
}

variable "instance_types" {
  description = "EC2 spot instance types"
  type        = list(string)
  default     = ["t4g.nano"]
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

# Cloudflare
variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for the domain"
  type        = string
  sensitive   = true
}

variable "env_content" {
  description = "Runtime .env content, stored in SSM"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "SSH public key content for EC2 instance access"
  type        = string
}

variable "ssh_allowed_ips" {
  description = "IP ranges (v4 or v6) allowed to SSH"
  type        = list(string)
}

# VPC
variable "use_existing_vpc" {
  description = "Use existing VPC instead of creating one"
  type        = bool
  default     = false
}

variable "existing_vpc_id" {
  description = "VPC ID when use_existing_vpc = true"
  type        = string
  default     = ""
}

variable "existing_subnet_ids" {
  description = "Public subnet IDs when use_existing_vpc = true"
  type        = list(string)
  default     = []
}

variable "vaultwarden_image" {
  description = "Vaultwarden Docker image -- pin to a specific tag to prevent breaking updates on spot replacement (e.g. vaultwarden/server:1.32.0)"
  type        = string
  default     = "vaultwarden/server:latest"
}
