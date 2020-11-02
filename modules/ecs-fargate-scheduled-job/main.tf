data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

module "this_job_label" {
  source = "./modules/aws-app-label"

  namespace   = var.app
  name        = var.name
  environment = var.environment
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/ecs/${module.this_job_label.id}"
  retention_in_days = var.logs_retention_in_days

  tags = module.this_job_label.tags
}

resource "aws_ecs_task_definition" "this" {
  family = module.this_job_label.id

  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = var.cpu
  memory = var.memory

  execution_role_arn = module.this_ecs_execution_role.this_iam_role_arn
  task_role_arn      = module.this_ecs_task_role.this_iam_role_arn

  container_definitions = jsonencode([{
    name  = var.name
    image = var.container_image

    environment = concat([
      {
        name  = "ECS_APP_NAME"
        value = var.app
      },
      {
        name  = "ECS_ENVIRONMENT_NAME"
        value = var.environment
      },
      {
        name  = "ECS_SERVICE_NAME"
        value = var.name
      },
    ], var.container_extra_environment)

    secrets = concat([], var.container_extra_secrets)

    logConfiguration = {
      logDriver = "awslogs"

      options = {
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-group"         = aws_cloudwatch_log_group.this.name
        "awslogs-stream-prefix" = var.name
      }
    }
  }])

  tags = module.this_job_label.tags
}

resource "aws_sfn_state_machine" "this" {
  name     = module.this_job_label.id
  role_arn = module.state_machine_role.this_iam_role_arn

  definition = jsonencode({
    "Version" = "1.0"
    "StartAt" = module.this_job_label.id

    "States" = {
      module.this_job_label.id = {
        "Type"     = "Task"
        "Resource" = "arn:aws:states:::ecs:runTask.sync"

        "Parameters" = {
          "LaunchType"      = "FARGATE"
          "PlatformVersion" = "LATEST"
          "Cluster"         = var.cluster_name
          "TaskDefinition"  = aws_ecs_task_definition.this.arn
          "Group.$"         = "$$.Execution.Name"

          "NetworkConfiguration" = {
            "AwsvpcConfiguration" = {
              "AssignPublicIp" = length(var.public_subnet_ids) == 0 ? "DISABLED" : "ENABLED"
              "Subnets"        = length(var.public_subnet_ids) == 0 ? var.private_subnet_ids : var.public_subnet_ids
              "SecurityGroups" = var.security_group_ids
            }
          }
        }

        "End" = true
      }
    }
  })

  tags = module.this_job_label.tags
}

resource "aws_cloudwatch_event_rule" "this" {
  name = module.this_job_label.tags

  schedule_expression = var.schedule_expression

  tags = module.this_job_label.tags
}

resource "aws_cloudwatch_event_target" "this" {
  # depends_on = [
  #   aws_cloudwatch_event_rule.this,
  #   aws_sfn_state_machine.this,
  # ]

  rule      = aws_cloudwatch_event_rule.this.name
  target_id = aws_cloudwatch_event_rule.this.name
  role_arn  = module.event_rule_role.this_iam_role_arn
  arn       = aws_sfn_state_machine.this.id
}
