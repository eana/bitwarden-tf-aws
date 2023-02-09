<!-- vim: set ft=markdown: -->

# Bitwarden in AWS

The configuration in this directory creates a Bitwarden instance by calling the
`bitwarden-aws-tf` module.

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

Note that this example may create resources which can cost money). Run
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

## Resources

| Name | Type |
|------|------|
| [local_file.this](https://registry.terraform.io/providers/hashicorp/local/latest/docs/data-sources/file) | data source |

## Inputs

No inputs.

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
