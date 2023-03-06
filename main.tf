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
      bitwarden_compose_key                  = aws_s3_object.compose.key
      backup_script_key                      = aws_s3_object.backup.key
      restore_script_key                     = aws_s3_object.restore.key
      AWS_SpotTerminationNotifier_script_key = aws_s3_object.AWS_SpotTerminationNotifier.key
      backup_schedule                        = var.backup_schedule
      bitwarden_env_key                      = aws_s3_object.env.key
      bitwarden-logrotate_key                = aws_s3_object.bitwarden-logrotate.key
      traefik-dynamic_key                    = aws_s3_object.traefik-dynamic.key
      traefik-logrotate_key                  = aws_s3_object.traefik-logrotate.key
      fail2ban_filter_key                    = aws_s3_object.fail2ban_filter.key
      fail2ban_jail_key                      = aws_s3_object.fail2ban_jail.key
      admin_fail2ban_filter_key              = aws_s3_object.admin_fail2ban_filter.key
      admin_fail2ban_jail_key                = aws_s3_object.admin_fail2ban_jail.key
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

  # For spot may need service link role defined aws iam create-service-linked-role --aws-service-name spot.amazonaws.com
  # Then add to KMS key policy
  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 0
    }
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.this.id
        version            = "$Latest"
      }
      dynamic "override" {
        for_each = ["t2.small"]
        content {
          instance_type = override.value
        }
      }
    }
  }

  dynamic "tag" {
    for_each = local.asg_tags
    content {
      key                 = tag.value["key"]
      value               = tag.value["value"]
      propagate_at_launch = tag.value["propagate_at_launch"]
    }
  }

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
