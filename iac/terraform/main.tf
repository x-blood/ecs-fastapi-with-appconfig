terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  backend "s3" {}
}

provider "aws" {
  region = "ap-northeast-1"
  default_tags {
    tags = {
      DoNotNuke = "true"
    }
  }
}

# ECR
resource "aws_ecr_repository" "yassan-fa-ac-repository" {
  name = "yassan-fa-ac-repository"
}

resource "aws_ecr_pull_through_cache_rule" "yassan-fa-ac-ecr-ptcr-ecr-public" {
  ecr_repository_prefix = "ecr-public"
  upstream_registry_url = "public.ecr.aws"
}

# ECS
resource "aws_ecs_cluster" "yassan-fa-ac-cluster" {
  name = "yassan-fa-ac-cluster"
}

# ALB
resource "aws_alb" "yassan-fa-ac-alb" {
  name            = "yassan-fa-ac-alb"
  security_groups = ["${aws_security_group.yassan-fa-ac-alb-sg.id}"]
  subnets         = [var.subnet_id_public_a, var.subnet_id_public_c]
  ip_address_type = "ipv4"
}

# ALB Target Group
resource "aws_lb_target_group" "yassan-fa-ac-alb-tg" {
  name             = "yassan-fa-ac-alb-tg"
  target_type      = "ip"
  protocol_version = "HTTP1"
  port             = 80
  protocol         = "HTTP"
  vpc_id           = var.vpc_id

  health_check {
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

# ALB Listener
resource "aws_lb_listener" "yassan-fa-ac-alb-listener" {
  load_balancer_arn = aws_alb.yassan-fa-ac-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.yassan-fa-ac-alb-tg.arn
  }
}

# Security Group ALB
resource "aws_security_group" "yassan-fa-ac-alb-sg" {
  vpc_id = var.vpc_id
  name   = "yassan-fa-ac-alb-sg"
}

resource "aws_security_group_rule" "yassan-fa-ac-alb-sg-ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.yassan-fa-ac-alb-sg.id
}

resource "aws_security_group_rule" "yassan-fa-ac-alb-sg-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.yassan-fa-ac-alb-sg.id
}

# Security Group ECS Service
resource "aws_security_group" "yassan-fa-ac-ecs-srv-sg" {
  vpc_id = var.vpc_id
  name   = "yassan-fa-ac-ecs-srv-sg"
}

resource "aws_security_group_rule" "yassan-fa-ac-ecs-srv-sg-ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.yassan-fa-ac-ecs-srv-sg.id
}

resource "aws_security_group_rule" "yassan-fa-ac-ecs-srv-sg-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.yassan-fa-ac-ecs-srv-sg.id
}

# Security Group VPC Endpoint
resource "aws_security_group" "yassan-fa-ac-vpce-sg" {
  vpc_id = var.vpc_id
  name   = "yassan-fa-ac-vpce-sg"
}

resource "aws_security_group_rule" "yassan-fa-ac-vpce-sg-ingress" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.yassan-fa-ac-vpce-sg.id
}

resource "aws_security_group_rule" "yassan-fa-ac-vpce-sg-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.yassan-fa-ac-vpce-sg.id
}

# VPC Endpoint
resource "aws_vpc_endpoint" "vpce_appconfig" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.ap-northeast-1.appconfig"
  vpc_endpoint_type = "Interface"

  subnet_ids = [
    var.subnet_id_private_a,
    var.subnet_id_private_c
  ]

  security_group_ids = [
    aws_security_group.yassan-fa-ac-vpce-sg.id,
  ]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "vpce_appconfigdata" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.ap-northeast-1.appconfigdata"
  vpc_endpoint_type = "Interface"

  subnet_ids = [
    var.subnet_id_private_a,
    var.subnet_id_private_c
  ]

  security_group_ids = [
    aws_security_group.yassan-fa-ac-vpce-sg.id,
  ]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "vpce_ecrapi" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.ap-northeast-1.ecr.api"
  vpc_endpoint_type = "Interface"

  subnet_ids = [
    var.subnet_id_private_a,
    var.subnet_id_private_c
  ]

  security_group_ids = [
    aws_security_group.yassan-fa-ac-vpce-sg.id,
  ]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "vpce_ecrdkr" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.ap-northeast-1.ecr.dkr"
  vpc_endpoint_type = "Interface"

  subnet_ids = [
    var.subnet_id_private_a,
    var.subnet_id_private_c
  ]

  security_group_ids = [
    aws_security_group.yassan-fa-ac-vpce-sg.id,
  ]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.ap-northeast-1.s3"
  route_table_ids = [
    var.route_table_id_private_a,
    var.route_table_id_private_c
  ]
}

resource "aws_vpc_endpoint" "vpce_logs" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.ap-northeast-1.logs"
  vpc_endpoint_type = "Interface"

  subnet_ids = [
    var.subnet_id_private_a,
    var.subnet_id_private_c
  ]

  security_group_ids = [
    aws_security_group.yassan-fa-ac-vpce-sg.id,
  ]

  private_dns_enabled = true
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "yassan-fa-ac-log-group" {
  name = "/ecs/yassan-fa-ac-task"
}

# AppConfig
resource "aws_appconfig_application" "yassan-ac-app" {
  name = "yassan-ac-app"
}

resource "aws_appconfig_configuration_profile" "yassan-ac-c-profile" {
  application_id = aws_appconfig_application.yassan-ac-app.id
  location_uri   = "hosted"
  name           = "yassan-ac-cprofile"
  type           = "AWS.AppConfig.FeatureFlags"
}

resource "aws_appconfig_hosted_configuration_version" "yassan-ac-hcv" {
  application_id           = aws_appconfig_application.yassan-ac-app.id
  configuration_profile_id = aws_appconfig_configuration_profile.yassan-ac-c-profile.configuration_profile_id
  content = jsonencode({
    flags : {
      featureA : {
        name : "featureA"
      }
    },
    values : {
      featureA : {
        enabled : "false"
      }
    },
    version : "1"
  })
  content_type = "application/json"
}

resource "aws_appconfig_environment" "yassan-ac-env-dev" {
  application_id = aws_appconfig_application.yassan-ac-app.id
  name           = "yassan-ac-env-dev"
}

resource "aws_appconfig_deployment_strategy" "yassan-ac-deploy-stg" {
  deployment_duration_in_minutes = 0
  growth_factor                  = 100
  final_bake_time_in_minutes     = 0
  name                           = "yassan-ac-deploy-stg"
  replicate_to                   = "NONE"
}

resource "aws_appconfig_deployment" "yassan-ac-deployment" {
  application_id           = aws_appconfig_application.yassan-ac-app.id
  configuration_profile_id = aws_appconfig_configuration_profile.yassan-ac-c-profile.configuration_profile_id
  configuration_version    = aws_appconfig_hosted_configuration_version.yassan-ac-hcv.version_number
  deployment_strategy_id   = aws_appconfig_deployment_strategy.yassan-ac-deploy-stg.id
  environment_id           = aws_appconfig_environment.yassan-ac-env-dev.environment_id
}

# IAM Role
resource "aws_iam_role" "yassan-fa-ac-ecs-task-execution-role" {
  name = "yassan-fa-ac-ecs-task-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]
}

resource "aws_iam_role" "yassan-fa-ac-ecs-task-role" {
  name = "yassan-fa-ac-ecs-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "yasan-fa-ac-ecs-task-policy" {
  name = "yasan-fa-ac-ecs-task-policy"
  role = aws_iam_role.yassan-fa-ac-ecs-task-role.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "appconfig:*",
        ],
        "Resource" : [
          "*"
        ]
      }
    ]
  })
}
