module "this_cluster_label" {
  source = "./modules/aws-app-label"

  namespace   = var.namespace
  name        = var.name
  environment = var.environment
}

resource "aws_ecs_cluster" "this" {
  name = module.this_cluster_label.id

  capacity_providers = var.capacity_providers

  dynamic "default_capacity_provider_strategy" {
    for_each = var.default_capacity_provider_strategies

    content {
      capacity_provider = default_capacity_provider_strategy.value["capacity_provider"]
      weight            = default_capacity_provider_strategy.value["weight"]
      base              = default_capacity_provider_strategy.value["base"]
    }
  }

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  tags = merge(var.tags, module.this_cluster_label.tags)

  lifecycle {
    create_before_destroy = true
  }
}

module "this_alb_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 3.0"

  count = var.create_load_balancer ? 1 : 0

  name        = "${module.this_cluster_label.id}-alb"
  description = "Access to the public facing Load Balancer"
  vpc_id      = var.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]

  tags = merge(var.tags, module.this_cluster_label.tags)
}

module "this_app_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 3.0"

  name   = "${module.this_cluster_label.id}-app"
  vpc_id = var.vpc_id

  ingress_with_self = [
    {
      rule = "all-all"
    },
  ]

  computed_ingress_with_source_security_group_id = var.create_load_balancer ? [
    {
      rule                     = "http-80-tcp"
      source_security_group_id = module.this_alb_security_group[0].this_security_group_id
    },
  ] : []

  number_of_computed_ingress_with_source_security_group_id = var.create_load_balancer ? 1 : 0

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]

  tags = merge(var.tags, module.this_cluster_label.tags)
}

module "this_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 5.0"

  count = var.create_load_balancer ? 1 : 0

  name = "${module.this_cluster_label.id}-alb"

  load_balancer_type = "application"

  vpc_id          = var.vpc_id
  subnets         = var.public_subnet_ids
  security_groups = [module.this_alb_security_group[0].this_security_group_id]

  target_groups = [
    {
      target_type      = "ip"
      backend_protocol = "HTTP"
      backend_port     = 80
    },
  ]

  http_tcp_listeners = [
    {
      port     = 80
      protocol = "HTTP"
    },
  ]

  tags = merge(var.tags, module.this_cluster_label.tags)
}
