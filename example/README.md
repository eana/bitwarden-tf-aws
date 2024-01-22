<!-- vim: set ft=markdown: -->

# Bitwarden in AWS

The Terraform files in this directory create a VPC and a Bitwarden instance, as
well as all the necessary network components, by invoking the
`terraform-aws-modules/vpc/aws` and `bitwarden-aws-tf` modules.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [How to use this](#how-to-use-this)

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
