output "volume_id" {
  description = "The volume ID"
  value       = aws_ebs_volume.this.id
}

output "public_ip" {
  description = "The public IP address the Bitwarden instance will have"
  value       = aws_eip.this.public_ip
}

output "sg_id" {
  description = "ID of the security group"
  value       = aws_security_group.this.id
}

output "iam_role_name" {
  description = "The IAM role for the Bitwarden Instance"
  value       = aws_iam_role.this.name
}

output "s3_bucket" {
  description = "The S3 bucket where the backups will be stored"
  value       = aws_s3_bucket.bucket.id
}

output "s3_resources" {
  description = "The S3 bucket where all the resource files will be stored"
  value       = aws_s3_bucket.resources.id
}

output "url" {
  description = "The URL where the Bitwarden Instance can be accessed"
  value       = "https://${aws_route53_record.this.name}"
}
