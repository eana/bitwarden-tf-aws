module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  count = var.use_existing_vpc ? 0 : 1

  name = "${var.name}-vpc"

  azs         = slice(data.aws_availability_zones.available.names, 0, 3)
  enable_ipv6 = true

  public_subnets              = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
  public_subnet_ipv6_prefixes = [0, 1, 2]
  private_subnets             = []

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway     = false
  create_igw             = true
  create_egress_only_igw = false

  tags = var.tags
}

resource "aws_security_group" "this" {
  name_prefix = "${var.name}-sg"
  description = "Security group for ${var.name}"
  vpc_id      = var.use_existing_vpc ? var.existing_vpc_id : module.vpc[0].vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
      for ip in var.ssh_allowed_ips : ip
      if !can(regex(":", ip))
    ]
    ipv6_cidr_blocks = [
      for ip in var.ssh_allowed_ips : ip
      if can(regex(":", ip))
    ]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = var.tags
}

resource "aws_ssm_parameter" "env" {
  name  = "/${var.name}/env"
  type  = "SecureString"
  value = var.env_content

  tags = var.tags
}

resource "aws_iam_role" "this" {
  name_prefix = "${var.name}-instance-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "ssm_read" {
  name = "${var.name}-ssm-read"
  role = aws_iam_role.this.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "ssm:GetParameter"
      Resource = aws_ssm_parameter.env.arn
    }]
  })
}

resource "aws_iam_role_policy" "ebs_attach" {
  name = "${var.name}-ebs-attach"
  role = aws_iam_role.this.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["ec2:AttachVolume"]
        Resource = [
          aws_ebs_volume.this.arn,
          "arn:aws:ec2:*:*:instance/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["ec2:DescribeVolumes", "ec2:DescribeInstances"]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_session_manager" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "this" {
  name_prefix = "${var.name}-instance-profile"
  role        = aws_iam_role.this.name
  tags        = var.tags
}

resource "aws_key_pair" "this" {
  key_name_prefix = "${var.name}-key-"
  public_key      = var.ssh_public_key
}

resource "aws_launch_template" "this" {
  name_prefix   = "${var.name}-lt-"
  image_id      = data.aws_ami.this.id
  instance_type = var.instance_types[0]
  key_name      = aws_key_pair.this.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.this.name
  }

  network_interfaces {
    delete_on_termination = true
    security_groups       = [aws_security_group.this.id]
    ipv6_address_count    = 1
  }

  user_data = base64encode(templatefile("${path.module}/data/user-data.sh", {
    name                  = var.name
    cloudflare_account_id = var.cloudflare_account_id
    tunnel_secret         = random_password.tunnel_secret.result
    tunnel_id             = cloudflare_zero_trust_tunnel_cloudflared.this.id
    domain                = var.domain
    backup_script         = file("${path.module}/data/backup.sh")
    restore_script        = file("${path.module}/data/restore.sh")
    spot_term_script      = file("${path.module}/data/AWS_SpotTerminationNotifier.sh")
    r2_config_script      = file("${path.module}/data/r2-config.sh")
    ebs_volume_id         = aws_ebs_volume.this.id
    r2_bucket_name        = cloudflare_r2_bucket.backups.name
    vaultwarden_image     = var.vaultwarden_image
  }))

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "${var.name}-instance" })
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "this" {
  name_prefix               = "${var.name}-asg-"
  vpc_zone_identifier       = var.use_existing_vpc ? [var.existing_subnet_ids[0]] : [module.vpc[0].public_subnets[0]]
  min_size                  = 0
  max_size                  = 1
  desired_capacity          = 1
  health_check_type         = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = var.name
    propagate_at_launch = true
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 0
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ebs_volume" "this" {
  availability_zone = var.use_existing_vpc ? data.aws_subnet.existing[0].availability_zone : module.vpc[0].azs[0]
  size              = 5
  type              = "gp3"
  encrypted         = true

  tags = merge(var.tags, {
    Name = "${var.name}-data"
  })

  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "this" {
  account_id    = var.cloudflare_account_id
  name          = var.name
  tunnel_secret = random_password.tunnel_secret.result
}

resource "random_password" "tunnel_secret" {
  length  = 32
  special = false
}

resource "cloudflare_ruleset" "https_redirect" {
  zone_id = var.cloudflare_zone_id
  name    = "HTTP to HTTPS redirect"
  kind    = "zone"
  phase   = "http_request_dynamic_redirect"

  rules = [{
    action      = "redirect"
    expression  = "(not ssl)"
    description = "Redirect HTTP to HTTPS"

    action_parameters = {
      from_value = {
        status_code = 301
        target_url = {
          expression = "concat(\"https://\", http.host, http.request.uri.path)"
        }
        preserve_query_string = true
      }
    }
  }]
}

resource "cloudflare_dns_record" "this" {
  zone_id = var.cloudflare_zone_id
  name    = var.domain
  content = "${cloudflare_zero_trust_tunnel_cloudflared.this.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "wildcard" {
  zone_id = var.cloudflare_zone_id
  name    = "*.${var.domain}"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.this.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

resource "cloudflare_r2_bucket" "backups" {
  account_id   = var.cloudflare_account_id
  name         = "${var.name}-backups"
  location     = "WEUR"
  jurisdiction = "eu"
}

resource "cloudflare_zero_trust_access_policy" "ssh" {
  account_id = var.cloudflare_account_id
  decision   = "allow"
  name       = "Allow SSH from IP ranges"

  include = [
    for ip in var.ssh_allowed_ips : {
      ip = {
        ip = ip
      }
    }
  ]
}

resource "cloudflare_zero_trust_access_application" "ssh" {
  account_id       = var.cloudflare_account_id
  name             = "${var.name} SSH"
  domain           = "ssh.${var.domain}"
  type             = "self_hosted"
  session_duration = "24h"

  policies = [{
    id         = cloudflare_zero_trust_access_policy.ssh.id
    precedence = 1
  }]
}
