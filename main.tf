# Primary VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name             = "vpc-${var.env}"
  cidr             = "10.0.0.0/16"
  azs              = ["us-east-1a", "us-east-1b", "us-east-1c"]
  database_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  public_subnets   = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]

  enable_nat_gateway                   = true
  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true

  tags = {
    Terraform   = "true"
    Environment = var.env
  }
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 6.0"

  name = "${var.env}-alb"

  load_balancer_type = "application"

  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnets
  security_groups = [aws_security_group.allow_http.id]

  access_logs = {
    bucket = "${var.env}-alb-logs"
  }

  target_groups = [
    {
      # name_prefix has a limit of 6 characters... which is strange, because the module example uses "default" as a valid prefix. Investigate?
      name_prefix      = "lucid"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
    }
  ]

  /*
  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = "SERVER_CERT_ARN"
      target_group_index = 0
    }
  ]
*/

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = {
    environment = var.env
  }
}

# Security group to allow Postgres traffic between RDS, Lambda, and Bastion Host
resource "aws_security_group" "allow_rds" {
  name        = "allow_rds"
  description = "Allow RDS traffic"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group_rule" "rds_in" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "tcp"
  security_group_id = aws_security_group.allow_rds.id
  self              = true
}

resource "aws_security_group_rule" "rds_out" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "tcp"
  security_group_id = aws_security_group.allow_rds.id
  self              = true
}

# Security group to allow Postgres traffic between RDS, Lambda, and Bastion Host
resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow HTTP/HTTPS traffic"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group_rule" "http_in" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.allow_http.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "http_out" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.allow_http.id
  cidr_blocks       = ["0.0.0.0/0"]
}

/*
resource "aws_security_group_rule" "https_in" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.allow_http.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "https_out" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.allow_http.id
  cidr_blocks       = ["0.0.0.0/0"]
}
*/
