locals {
  az = "eu-west-1a"

  default_tags = {
    Name       = var.name
    created_by = "terraform"
    repository = "aws-infra-tf"
    directory  = "/bitwarden"
  }

  asg_tags = concat([
    for key, value in var.tags : {
      key                 = key
      value               = value
      propagate_at_launch = true
    }
    ], [
    {
      key                 = "Name"
      value               = var.name
      propagate_at_launch = true
    }
    ]
  )
}
