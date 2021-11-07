<!-- vim: set ft=markdown: -->

# Bitwarden in AWS

The configuration in this directory creates a Bitwarden instance by calling the
`bitwarden-aws-tf` module.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.12.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bitwarden"></a> [bitwarden](#module\_bitwarden) | ../ |  |

## Resources

No resources.

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
