module "bitwarden" {
  source = "../"

  domain                = var.domain
  name                  = var.name
  instance_types        = var.instance_types
  tags                  = var.tags
  cloudflare_account_id = var.cloudflare_account_id
  cloudflare_zone_id    = var.cloudflare_zone_id
  env_content           = var.env_content
  ssh_public_key        = var.ssh_public_key
  ssh_allowed_ips       = var.ssh_allowed_ips
  use_existing_vpc      = var.use_existing_vpc
  existing_vpc_id       = var.existing_vpc_id
  existing_subnet_ids   = var.existing_subnet_ids
}
