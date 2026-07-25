output "url" {
  description = "Vaultwarden URL"
  value       = "https://${var.domain}"
}

output "iam_role_name" {
  description = "Instance IAM role name"
  value       = aws_iam_role.this.name
}

output "sg_id" {
  description = "Security group ID"
  value       = aws_security_group.this.id
}

output "volume_id" {
  description = "EBS volume ID"
  value       = aws_ebs_volume.this.id
}

output "r2_backup_bucket" {
  description = "R2 backup bucket name"
  value       = cloudflare_r2_bucket.backups.name
}

output "tunnel_id" {
  description = "Cloudflare tunnel ID"
  value       = cloudflare_zero_trust_tunnel_cloudflared.this.id
}
