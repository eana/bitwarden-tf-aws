# bitwarden-tf-aws

Terraform module for deploying a cheap yet stable
[vaultwarden](https://github.com/dani-garcia/vaultwarden) (formerly
bitwarden_rs) to AWS.

<!-- vim-markdown-toc GFM -->

* [Prerequisites](#prerequisites)
* [Features](#features)
* [How it works](#how-it-works)
* [Usage](#usage)
    * [Secrets](#secrets)
    * [Terraform](#terraform)
* [TODO](#todo)
* [Contributions](#contributions)
* [Requirements](#requirements)
* [Providers](#providers)
* [Modules](#modules)
* [Resources](#resources)
* [Inputs](#inputs)
* [Outputs](#outputs)

<!-- vim-markdown-toc -->

## Prerequisites

- Route53 hosted zone
- SMTP credentials
- EC2 key pair
- KMS key

## Features

- HTTPS using LetsEncrypt
- Backups to S3 (daily by default)
- fail2ban and logrotate
- Auto healing using an auto scaling group
- Saving cost using a spot instance
- Fixed source IP address by reattaching ENI
- Encrypted secrets using [mozilla/sops](https://github.com/mozilla/sops)

## How it works

This module provisions the following resources:

- Auto Scaling Group with mixed instances policy
- Launch Template
- Elastic IP
- Elastic Network Interface
- Security Group
- IAM Role for ENI and EBS attachment and S3 for file operations

By default, an instance of the latest Amazon Linux 2 is launched.
The instance will run [init.sh](data/init.sh) to:

1. Attach the ENI to `eth1`
2. Attach the EBS volume as `/dev/xvdf` and mount it
3. Install and configure `docker`, `docker-compose`, `sops`, `fail2ban`
4. Start `Bitwarden`
5. Switch the default route to `eth1`

## Usage

### Secrets

The secrets are encrypted and stored in the `env.enc` file.
The file format is:

```env
acme_email=email@example.com
signups_allowed=false
domain=bitwarden.example.com
smtp_host=smtp.gmail.com
smtp_port=587
smtp_ssl=true
smtp_username=username@gmail.com
smtp_password="V3ryStr0ngPa$sw0rd!"
enable_admin_page=true
admin_token=0YakKKYV01Qyz2Y3ynrJVYhw4fy1HtH+oCyVK8k3LhvnpawvkmUT/LZAibYJp3Eq
bucket=bitwarden-bucket
db_user=bitwarden
db_user_password=ChangeThisVeryStrongPassword
db_root_password=ReplaceThisEvenStrongerPassword
```

**NOTE**: I strongly advise **NOT** to enable the Admin Page, hence to remove
the lines containing `enable_admin_page` and `admin_token`. If you still want
to enable it, you should at least generate a 48 char long password.

```bash
$ openssl rand -base64 48
```

Once the `env.enc` file is populated with the correct secrets it must be
encrypted. This file should never be left unencrypted.

```bash
$ SOPS_KMS_ARN="KMS_KEY_ARN" sops -e -i data/env.enc
```

replace `KMS_KEY_ARN` with the ARN of the KMS you want to use

### Terraform

```terraform
provider "aws" {
  region = "eu-west-1"
}

data "local_file" "this" {
  filename = "${path.module}/env.enc"
}

data "aws_kms_key" "this" {
  key_id = "alias/bitwarden-sops-encryption-key-prod"
}

module "bitwarden" {
  source       = "../"
  name         = "bitwarden"
  domain       = "bitwarden.example.org"
  environment  = "prod"
  route53_zone = "example.org."
  ssh_cidr     = ["212.178.73.60/32"]
  env_file     = data.local_file.this.content
}
```

## TODO

1. ~~Add a restore script~~
2. ~~Manage dependencies with
   [renovate-bot](https://github.com/renovatebot/renovate)~~
3. ~~Implement a retry mechanism when attaching ENI and EBS~~
4. ~~Detect if the EBS volume has been formatted or not~~
5. ~~Add logrotate for Traefik logs~~

## Contributions

This is an open source software. Feel free to open issues and pull requests.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.56.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 1.4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.56.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_ebs_volume.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_volume) | resource |
| [aws_eip.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_iam_instance_profile.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.ebs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.eni](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_launch_template.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_network_interface.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [aws_route53_record.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_s3_bucket.bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.resources](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_object.AWS_SpotTerminationNotifier](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object) | resource |
| [aws_s3_bucket_object.admin_fail2ban_filter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object) | resource |
| [aws_s3_bucket_object.admin_fail2ban_jail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object) | resource |
| [aws_s3_bucket_object.backup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object) | resource |
| [aws_s3_bucket_object.bitwarden-logrotate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object) | resource |
| [aws_s3_bucket_object.compose](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object) | resource |
| [aws_s3_bucket_object.env](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object) | resource |
| [aws_s3_bucket_object.fail2ban_filter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object) | resource |
| [aws_s3_bucket_object.fail2ban_jail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object) | resource |
| [aws_s3_bucket_object.restore](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object) | resource |
| [aws_s3_bucket_object.traefik-dynamic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object) | resource |
| [aws_s3_bucket_object.traefik-logrotate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object) | resource |
| [aws_s3_bucket_policy.policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.resources](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_ami.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_iam_policy_document.s3policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_route53_zone.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_subnets.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_tags"></a> [additional\_tags](#input\_additional\_tags) | Additional tags to apply to resources created with this module | `map(string)` | `{}` | no |
| <a name="input_backup_schedule"></a> [backup\_schedule](#input\_backup\_schedule) | A cron expression to describe how often your data is backed up | `string` | `"0 9 * * *"` | no |
| <a name="input_bucket_version_expiration_days"></a> [bucket\_version\_expiration\_days](#input\_bucket\_version\_expiration\_days) | Specifies when noncurrent object versions expire | `number` | `30` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | The domain name for the Bitwarden instance | `string` | n/a | yes |
| <a name="input_env_file"></a> [env\_file](#input\_env\_file) | The name of the default docker-compose encrypted env file | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | The environment to deploy to | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name to be used as identifier | `string` | `"bitwarden"` | no |
| <a name="input_route53_zone"></a> [route53\_zone](#input\_route53\_zone) | The zone in which the DNS record will be created | `string` | n/a | yes |
| <a name="input_ssh_cidr"></a> [ssh\_cidr](#input\_ssh\_cidr) | The IP ranges from where the SSH connections will be allowed | `list(any)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to resources created with this module | `map(any)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_iam_role_name"></a> [iam\_role\_name](#output\_iam\_role\_name) | The IAM role for the Bitwarden Instance |
| <a name="output_public_ip"></a> [public\_ip](#output\_public\_ip) | The public IP address the Bitwarden instance will have |
| <a name="output_s3_bucket"></a> [s3\_bucket](#output\_s3\_bucket) | The S3 bucket where the backups will be stored |
| <a name="output_s3_resources"></a> [s3\_resources](#output\_s3\_resources) | The S3 bucket where all the resource files will be stored |
| <a name="output_sg_id"></a> [sg\_id](#output\_sg\_id) | ID of the security group |
| <a name="output_url"></a> [url](#output\_url) | The URL where the Bitwarden Instance can be accessed |
| <a name="output_volume_id"></a> [volume\_id](#output\_volume\_id) | The volume ID |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
