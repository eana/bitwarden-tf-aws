resource "aws_security_group" "this" {
  name        = var.name
  vpc_id      = data.aws_vpc.this.id
  description = "Security group for EC2 instance ${var.name}"
  tags        = local.default_tags
}

resource "aws_security_group_rule" "egress" {
  security_group_id = aws_security_group.this.id
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"] # tfsec:ignore:AWS007
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  description       = "Allow all outbound traffic"
}

resource "aws_security_group_rule" "nat_ssh" {
  security_group_id = aws_security_group.this.id
  type              = "ingress"
  cidr_blocks       = ["85.230.207.252/32", "91.206.78.234/32", "90.224.39.53/32"]
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  description       = "Allow incoming SSH connections only from certain IPs."
}

resource "aws_network_interface" "this" {
  security_groups   = [aws_security_group.this.id]
  subnet_id         = data.aws_subnets.this.ids[0]
  source_dest_check = false
  description       = "ENI for EC2 instance ${var.name}"
  tags              = local.default_tags
}

resource "aws_eip" "this" {
  network_interface = aws_network_interface.this.id
  tags              = local.default_tags
}

resource "aws_launch_template" "this" {
  name     = var.name
  image_id = data.aws_ami.this.id
  key_name = "admin-${terraform.workspace}"

  iam_instance_profile {
    arn = aws_iam_instance_profile.this.arn
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.this.id]
    delete_on_termination       = true
  }

  user_data = base64encode(
    templatefile("${path.module}/data/init.sh", {
      eni_id                    = aws_network_interface.this.id
      volume_id                 = aws_ebs_volume.this.id
      bucket                    = aws_s3_bucket.bucket.id
      resources_bucket          = aws_s3_bucket.resources.id
      bitwarden_compose_key     = aws_s3_bucket_object.compose.key
      logrotate_key             = aws_s3_bucket_object.logrotate.key
      fail2ban_filter_key       = aws_s3_bucket_object.fail2ban_filter.key
      fail2ban_jail_key         = aws_s3_bucket_object.fail2ban_jail.key
      admin_fail2ban_filter_key = aws_s3_bucket_object.admin_fail2ban_filter.key
      admin_fail2ban_jail_key   = aws_s3_bucket_object.admin_fail2ban_jail.key
    })
  )

  description = "Launch template for EC2 instance ${var.name}"

  tags = merge(
    local.default_tags,
  )
}

resource "aws_autoscaling_group" "this" {
  name                = var.name
  min_size            = 1
  max_size            = 1
  vpc_zone_identifier = ["subnet-0f08f5059a3ca78fc"]

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 1
      on_demand_percentage_above_base_capacity = 100
    }
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.this.id
        version            = "$Latest"
      }
      dynamic "override" {
        for_each = ["t2.micro"]
        content {
          instance_type = override.value
        }
      }
    }
  }

  tags = local.asg_tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ebs_volume" "this" {
  availability_zone = local.az
  size              = 5

  tags = merge(
    local.default_tags,
  )
}
