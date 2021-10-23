resource "aws_secretsmanager_secret" "config" {
  name        = var.name
  description = "bitwarden configuration"
}

resource "aws_secretsmanager_secret_version" "config_value" {
  secret_id = aws_secretsmanager_secret.config.id

  secret_string = templatefile("data/env", {
    # FIXME: We need a better way to handle this
    acme_email        = "whaever@example.com"
    signups_allowed   = false
    domain            = var.domain
    smtp_host         = "smtp.gmail.com"
    smtp_port         = "587"
    smtp_ssl          = true
    smtp_username     = "username@example.com"
    smtp_password     = "superstrongpassword"
    enable_admin_page = true
    # openssl rand -base64 48
    admin_token     = "0YakKKYV01Qyz2Y3ynrJVYhw4fy1HtH+oCyVK8k3LhvnpawvkmUT/LZAibYJp3Eq"
    backup_schedule = "0 9 * * *"
    bucket          = aws_s3_bucket.bucket.id
  })
}
