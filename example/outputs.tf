output "url" {
  description = "Vaultwarden URL"
  value       = module.bitwarden.url
}

output "iam_role_name" {
  description = "Instance IAM role name"
  value       = module.bitwarden.iam_role_name
}

output "sg_id" {
  description = "Security group ID"
  value       = module.bitwarden.sg_id
}

output "volume_id" {
  description = "EBS volume ID"
  value       = module.bitwarden.volume_id
}

output "r2_backup_bucket" {
  description = "R2 backup bucket name"
  value       = module.bitwarden.r2_backup_bucket
}

output "tunnel_id" {
  description = "Cloudflare tunnel ID"
  value       = module.bitwarden.tunnel_id
}
