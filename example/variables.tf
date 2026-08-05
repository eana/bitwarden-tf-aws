variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  sensitive   = true
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
  default     = ["t4g.nano", "t4g.micro"]
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
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
  description = "Runtime .env file content -- stored in SSM and fetched by instance at boot"
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
  description = "Subnet IDs when use_existing_vpc = true"
  type        = list(string)
  default     = []
}
