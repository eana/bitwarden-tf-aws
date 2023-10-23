<!-- vim: set ft=markdown: -->

# Bitwarden in AWS

The Terraform files in this directory create a VPC and a Bitwarden instance, as
well as all the necessary network components, by invoking the
`terraform-aws-modules/vpc/aws` and `bitwarden-aws-tf` modules.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [How to use this](#how-to-use-this)
- [Requirements](#requirements)
- [Providers](#providers)
- [Modules](#modules)
- [Resources](#resources)
- [Inputs](#inputs)
- [Outputs](#outputs)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## How to use this

1. Create a file called `env.enc` with the following content:

```
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

2. Encrypt `env.enc`

```bash
SOPS_KMS_ARN="KMS_KEY_ARN" sops -e -i env.enc
```

replace `KMS_KEY_ARN` with the ARN of the KMS you want to use

3. Plan and apply the terraform code

```bash
terraform init
terraform plan
terraform apply
```

Note that this example may create resources which will cost money. Run
`terraform destroy` when you don't need these resources.

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
| <a name="provider_local"></a> [local](#provider\_local) | >= 1.4 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bitwarden"></a> [bitwarden](#module\_bitwarden) | ../ | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 5.1.2 |

## Resources

| Name | Type |
|------|------|
| [local_file.this](https://registry.terraform.io/providers/hashicorp/local/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_azs"></a> [azs](#input\_azs) | List of availability zones/ | `map(list(string))` | <pre>{<br>  "prod": [<br>    "eu-west-1a",<br>    "eu-west-1b",<br>    "eu-west-1c"<br>  ],<br>  "test": [<br>    "eu-west-1a",<br>    "eu-west-1b",<br>    "eu-west-1c"<br>  ]<br>}</pre> | no |
| <a name="input_cidr"></a> [cidr](#input\_cidr) | The CIDR block for the VPC. | `map(string)` | <pre>{<br>  "prod": "10.100.0.0/16",<br>  "test": "10.101.0.0/16"<br>}</pre> | no |
| <a name="input_environment"></a> [environment](#input\_environment) | The environment to deploy the app in. | `string` | `"prod"` | no |
| <a name="input_private_subnets"></a> [private\_subnets](#input\_private\_subnets) | List of cidr\_blocks of private subnets. | `map(list(string))` | <pre>{<br>  "prod": [<br>    "10.100.96.0/20",<br>    "10.100.112.0/20",<br>    "10.100.128.0/20"<br>  ],<br>  "test": [<br>    "10.101.96.0/20",<br>    "10.101.112.0/20",<br>    "10.101.128.0/20"<br>  ]<br>}</pre> | no |
| <a name="input_public_subnets"></a> [public\_subnets](#input\_public\_subnets) | List of cidr\_blocks of public subnets. | `map(list(string))` | <pre>{<br>  "prod": [<br>    "10.100.0.0/20",<br>    "10.100.16.0/20",<br>    "10.100.32.0/20"<br>  ],<br>  "test": [<br>    "10.101.0.0/20",<br>    "10.101.16.0/20",<br>    "10.101.32.0/20"<br>  ]<br>}</pre> | no |

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
| <a name="output_vpc_azs"></a> [vpc\_azs](#output\_vpc\_azs) | The list of availability zones created. |
| <a name="output_vpc_private_subnets"></a> [vpc\_private\_subnets](#output\_vpc\_private\_subnets) | List of IDs of private subnets. |
| <a name="output_vpc_public_subnets"></a> [vpc\_public\_subnets](#output\_vpc\_public\_subnets) | List of IDs of public subnets. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
