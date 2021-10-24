#tfsec:ignore:AWS002
resource "aws_s3_bucket" "bucket" {
  bucket = "${var.name}-bucket"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning {
    enabled = true
  }

  lifecycle_rule {
    enabled = true
    noncurrent_version_expiration {
      days = var.bucket_version_expiration_days
    }
  }

  tags = merge(
    local.default_tags,
    {
      Name = "bitwarden-bucket"
    },
  )
}

#tfsec:ignore:AWS002
resource "aws_s3_bucket" "resources" {
  bucket = "${var.name}-resources"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning {
    enabled = true
  }

  tags = merge(
    local.default_tags,
    {
      Name = "bitwarden-resources-bucket"
    },
  )
}

resource "aws_s3_bucket_object" "compose" {
  bucket                 = aws_s3_bucket.resources.id
  key                    = "bitwarden-docker-compose.yml"
  content                = file("data/docker-compose.yml")
  server_side_encryption = "AES256"
}

resource "aws_s3_bucket_object" "backup" {
  bucket = aws_s3_bucket.resources.id
  key    = "bitwarden-backup.sh"
  content = templatefile("${path.module}/data/backup.sh", {
    bucket = aws_s3_bucket.bucket.id
  })
  server_side_encryption = "AES256"
}
resource "aws_s3_bucket_object" "env" {
  bucket                 = aws_s3_bucket.resources.id
  key                    = "bitwarden-env"
  content                = replace(data.local_file.this.content, "KMS_KEY_ARN", data.aws_kms_key.this.arn)
  server_side_encryption = "AES256"
}

resource "aws_s3_bucket_object" "logrotate" {
  bucket                 = aws_s3_bucket.resources.id
  key                    = "bitwarden-logrotate"
  content                = file("data/bitwarden-logrotate")
  server_side_encryption = "AES256"
}

resource "aws_s3_bucket_object" "fail2ban_filter" {
  bucket                 = aws_s3_bucket.resources.id
  key                    = "fail2ban/filter"
  content                = file("data/fail2ban/bitwarden-fail2ban-filter")
  server_side_encryption = "AES256"
}

resource "aws_s3_bucket_object" "admin_fail2ban_filter" {
  bucket                 = aws_s3_bucket.resources.id
  key                    = "fail2ban/admin-filter"
  content                = file("data/fail2ban/bitwarden-admin-fail2ban-filter")
  server_side_encryption = "AES256"
}

resource "aws_s3_bucket_object" "fail2ban_jail" {
  bucket                 = aws_s3_bucket.resources.id
  key                    = "fail2ban/jail"
  content                = file("data/fail2ban/bitwarden-fail2ban-jail")
  server_side_encryption = "AES256"
}

resource "aws_s3_bucket_object" "admin_fail2ban_jail" {
  bucket                 = aws_s3_bucket.resources.id
  key                    = "fail2ban/admin-jail"
  content                = file("data/fail2ban/bitwarden-admin-fail2ban-jail")
  server_side_encryption = "AES256"
}

resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket                  = aws_s3_bucket.bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "resources" {
  bucket                  = aws_s3_bucket.resources.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.s3policy.json
}
