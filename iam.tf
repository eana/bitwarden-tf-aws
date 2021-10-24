resource "aws_iam_role" "this" {
  name = var.name
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = merge(
    local.default_tags,
  )
}

resource "aws_iam_role_policy" "eni" {
  role   = aws_iam_role.this.name
  name   = "${var.name}-eni"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AttachNetworkInterface"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "ebs" {
  role = aws_iam_role.this.name
  name = "${var.name}-ebs"

  policy = <<EOF
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Effect":"Allow",
      "Action":[
        "ec2:AttachVolume",
        "ec2:DetachVolume"
      ],
      "Resource": "arn:aws:ec2:*:*:instance/*",
      "Condition":{
        "StringEquals":{
          "aws:ResourceTag/Name":"bitwarden"
        }
      }
    },
    {
      "Effect":"Allow",
      "Action":[
        "ec2:AttachVolume",
        "ec2:DetachVolume"
      ],
      "Resource": "arn:aws:ec2:*:*:volume/*",
      "Condition":{
        "StringEquals":{
          "aws:ResourceTag/Name":"bitwarden"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "s3" {
  name   = "${var.name}-s3"
  role   = aws_iam_role.this.id
  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "s3:ListBucket"
        ],
        "Effect": "Allow",
        "Resource": "${aws_s3_bucket.bucket.arn}"
      },
      {
        "Action": [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObjectAcl"
        ],
        "Effect": "Allow",
        "Resource": "${aws_s3_bucket.bucket.arn}/*"
      },
      {
        "Action": [
          "s3:ListBucket"
        ],
        "Effect": "Allow",
        "Resource": "${aws_s3_bucket.resources.arn}"
      },
      {
        "Action": [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObjectAcl"
        ],
        "Effect": "Allow",
        "Resource": "${aws_s3_bucket.resources.arn}/*"
      }
    ]
  }
  EOF
}

data "aws_iam_policy_document" "s3policy" {
  statement {
    sid       = "AllowBitwardenInstanceProfile"
    effect    = "Allow"
    resources = [aws_s3_bucket.bucket.arn]
    actions   = ["s3:ListBucket"]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.this.arn]
    }
  }

  statement {
    sid       = "AllowBitwardenInstanceProfileContents"
    effect    = "Allow"
    resources = ["${aws_s3_bucket.bucket.arn}/*"]
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObjectAcl"
    ]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.this.arn]
    }
  }

  statement {
    sid       = "DenyIncorrectEncryptionHeader"
    effect    = "Deny"
    resources = ["${aws_s3_bucket.bucket.arn}/*"]
    actions   = ["s3:PutObject"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["AES256"]
    }
  }

  statement {
    sid       = "DenyUnencryptedObjectUploads"
    effect    = "Deny"
    resources = ["${aws_s3_bucket.bucket.arn}/*"]
    actions   = ["s3:PutObject"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Null"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["true"]
    }
  }
}

resource "aws_iam_instance_profile" "this" {
  name = var.name
  role = aws_iam_role.this.name
}
