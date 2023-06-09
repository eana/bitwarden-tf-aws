output "vpc_azs" {
  value       = module.vpc.azs
  description = "The list of availability zones created."
}

output "vpc_public_subnets" {
  value       = module.vpc.public_subnets
  description = "List of IDs of public subnets."
}

output "vpc_private_subnets" {
  value       = module.vpc.private_subnets
  description = "List of IDs of private subnets."
}

output "volume_id" {
  description = "The volume ID"
  value       = module.bitwarden.volume_id
}

output "public_ip" {
  description = "The public IP address the Bitwarden instance will have"
  value       = module.bitwarden.public_ip
}

output "sg_id" {
  description = "ID of the security group"
  value       = module.bitwarden.sg_id
}

output "iam_role_name" {
  description = "The IAM role for the Bitwarden Instance"
  value       = module.bitwarden.iam_role_name
}

output "s3_bucket" {
  description = "The S3 bucket where the backups will be stored"
  value       = module.bitwarden.s3_bucket
}

output "s3_resources" {
  description = "The S3 bucket where all the resource files will be stored"
  value       = module.bitwarden.s3_resources
}

output "url" {
  description = "The URL where the Bitwarden Instance can be accessed"
  value       = module.bitwarden.url
}
