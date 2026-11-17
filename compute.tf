# Latest Amazon Linux 2023 AMI, looked up automatically
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# The recipe for each server
resource "aws_launch_template" "app" {
  name_prefix            = "3tier-app-"
  image_id               = data.aws_ssm_parameter.al2023.value
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.app.id]
  user_data              = base64encode(file("${path.module}/user_data.sh"))

  metadata_options {
    http_tokens = "required" # enforce IMDSv2 (security best practice)
  }
}

# Keeps 2 servers running across 2 AZs, registered with the ALB
resource "aws_autoscaling_group" "app" {
  name                      = "3tier-asg"
  min_size                  = 2
  max_size                  = 4
  desired_capacity          = 2
  vpc_zone_identifier       = aws_subnet.private[*].id
  target_group_arns         = [aws_lb_target_group.app.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 120

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "3tier-app"
    propagate_at_launch = true
  }
}

# Scale out when average CPU goes above 50%
resource "aws_autoscaling_policy" "cpu" {
  name                   = "cpu-target-50"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50
  }
}