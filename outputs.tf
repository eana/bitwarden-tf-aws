### VPC ###
output "vpc_azs" {
  value       = var.enable_vpc ? module.vpc.azs : "VPC feature not enabled"
  description = "The list of availability zones created."
}

output "vpc_public_subnets" {
  value       = var.enable_vpc ? module.vpc.public_subnets : "VPC feature not enabled"
  description = "List of IDs of public subnets."
}

output "vpc_private_subnets" {
  value       = var.enable_vpc ? module.vpc.private_subnets : "VPC feature not enabled"
  description = "List of IDs of private subnets."
}

### BITWARDEN ###
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
  value       = var.enable_route53 ? "https://${aws_route53_record.this[0].name}" : "https://${aws_eip.this.public_ip}"
}
