# Fetch Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_launch_template" "asg_worker" {
  name = "asg_worker"

  cpu_options {
    core_count       = 4
    threads_per_core = 2
  }

  disable_api_termination = false

  ebs_optimized = true

  iam_instance_profile {
    name = aws_iam_instance_profile.worker_profile.arn
  }

  image_id = data.aws_ami.amazon_linux_2.image_id

  instance_initiated_shutdown_behavior = "terminate"

  instance_market_options {
    market_type = "spot"
  }

  instance_type = "t2.micro"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  monitoring {
    enabled = true
  }

  vpc_security_group_ids = [aws_security_group.allow_http.id, aws_security_group.allow_rds.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.env}-worker"
    }
  }
}

resource "aws_autoscaling_group" "asg" {
  name                      = "${var.env}-asg"
  max_size                  = 2
  min_size                  = 0
  health_check_grace_period = 300
  health_check_type         = "EC2"
  desired_capacity          = 2
  force_delete              = false
  launch_template {
    id      = aws_launch_template.asg_worker.id
    version = "$Latest"
  }
  vpc_zone_identifier = module.vpc.private_subnets

  tag {
    key                 = "environment"
    value               = var.env
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.asg.id
  alb_target_group_arn   = module.alb.target_group_arns[0]
}

