<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | = 1.0.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | = 3.63.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | = 3.63.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group.this](https://registry.terraform.io/providers/hashicorp/aws/3.63.0/docs/resources/autoscaling_group) | resource |
| [aws_ebs_volume.this](https://registry.terraform.io/providers/hashicorp/aws/3.63.0/docs/resources/ebs_volume) | resource |
| [aws_eip.this](https://registry.terraform.io/providers/hashicorp/aws/3.63.0/docs/resources/eip) | resource |
| [aws_iam_instance_profile.this](https://registry.terraform.io/providers/hashicorp/aws/3.63.0/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/3.63.0/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.ebs](https://registry.terraform.io/providers/hashicorp/aws/3.63.0/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.eni](https://registry.terraform.io/providers/hashicorp/aws/3.63.0/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.s3](https://registry.terraform.io/providers/hashicorp/aws/3.63.0/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.sm](https://registry.terraform.io/providers/hashicorp/aws/3.63.0/docs/resources/iam_role_policy) | resource |
| [aws_launch_template.this](https://registry.terraform.io/providers/hashicorp/aws/3.63.0/docs/resources/launch_template) | resource |
| [aws_network_interface.this](https://registry.terraform.io/providers/hashicorp/aws/3.63.0/docs/resources/network_interface) | resource |
| [aws_route53_record.this](https://registry.terraform.io/providers/hashicorp/aws/3.63.0/docs/resources/route53_record) | resource |
| [aws_s3_bucket.bucket](https://registry.terraform.io/providers/hashicorp/aws/3.63.0/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.resources](https://registry.terraform.io/providers/hashicorp/aws/3.63.0/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_object.admin_fail2ban_filter](https://registry.terraform.io/providers/hashicorp/aws/3.63.0/docs/resources/s3_bucket_object) | resource |
| [aws_s3_bucket_object.admin_fail2ban_jail](https://registry.terraform.io/providers/hashicorp/aws/3.63.0/docs/resources/s3_bucket_object) | resource |
| [aws_s3_bucket_object.compose](https://registry.terraform.io/providers/hashicorp/aws/3.63.0/docs/resources/s3_bucket_object) | resource |
| [aws_s3_bucket_object.fail2ban_filter](https://registry.terraform.io/providers/hashicorp/aws/3.63.0/docs/resources/s3_bucket_object) | resource |
| [aws_s3_bucket_object.fail2ban_jail](https://registry.terraform.io/providers/hashicorp/aws/3.63.0/docs/resources/s3_bucket_object) | resource |
| [aws_s3_bucket_object.logrotate](https://registry.terraform.io/providers/hashicorp/aws/3.63.0/docs/resources/s3_bucket_object) | resource |
| [aws_s3_bucket_policy.policy](https://registry.terraform.io/providers/hashicorp/aws/3.63.0/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.bucket](https://registry.terraform.io/providers/hashicorp/aws/3.63.0/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.resources](https://registry.terraform.io/providers/hashicorp/aws/3.63.0/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_secretsmanager_secret.config](https://registry.terraform.io/providers/hashicorp/aws/3.63.0/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.config_value](https://registry.terraform.io/providers/hashicorp/aws/3.63.0/docs/resources/secretsmanager_secret_version) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/3.63.0/docs/resources/security_group) | resource |
| [aws_ami.this](https://registry.terraform.io/providers/hashicorp/aws/3.63.0/docs/data-sources/ami) | data source |
| [aws_iam_policy_document.s3policy](https://registry.terraform.io/providers/hashicorp/aws/3.63.0/docs/data-sources/iam_policy_document) | data source |
| [aws_route53_zone.this](https://registry.terraform.io/providers/hashicorp/aws/3.63.0/docs/data-sources/route53_zone) | data source |
| [aws_subnets.this](https://registry.terraform.io/providers/hashicorp/aws/3.63.0/docs/data-sources/subnets) | data source |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/3.63.0/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bucket_version_expiration_days"></a> [bucket\_version\_expiration\_days](#input\_bucket\_version\_expiration\_days) | Specifies when noncurrent object versions expire | `number` | `30` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | The domain name for the Bitwarden instance | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name to be used  as identifier | `string` | `"bitwarden"` | no |
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
