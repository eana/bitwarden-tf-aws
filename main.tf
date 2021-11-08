resource "aws_launch_template" "this" {
  name     = var.name
  image_id = data.aws_ami.this.id
  key_name = "admin-${var.environment}"

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
      eni_id                                 = aws_network_interface.this.id
      volume_id                              = aws_ebs_volume.this.id
      bucket                                 = aws_s3_bucket.bucket.id
      resources_bucket                       = aws_s3_bucket.resources.id
      bitwarden_compose_key                  = aws_s3_bucket_object.compose.key
      backup_script_key                      = aws_s3_bucket_object.backup.key
      AWS_SpotTerminationNotifier_script_key = aws_s3_bucket_object.AWS_SpotTerminationNotifier.key
      backup_schedule                        = var.backup_schedule
      bitwarden_env_key                      = aws_s3_bucket_object.env.key
      bitwarden-logrotate_key                = aws_s3_bucket_object.bitwarden-logrotate.key
      traefik-logrotate_key                  = aws_s3_bucket_object.traefik-logrotate.key
      fail2ban_filter_key                    = aws_s3_bucket_object.fail2ban_filter.key
      fail2ban_jail_key                      = aws_s3_bucket_object.fail2ban_jail.key
      admin_fail2ban_filter_key              = aws_s3_bucket_object.admin_fail2ban_filter.key
      admin_fail2ban_jail_key                = aws_s3_bucket_object.admin_fail2ban_jail.key
    })
  )

  description = "Launch template for EC2 instance ${var.name}"

  tags = merge(
    local.default_tags,
    var.additional_tags,
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
    var.additional_tags,
  )
}
