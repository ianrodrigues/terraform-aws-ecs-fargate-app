data "aws_iam_policy_document" "secrets" {
  statement {
    actions   = ["ssm:GetParameters"]
    resources = ["arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/*"]

    condition {
      test     = "StringEquals"
      variable = "ssm:ResourceTag/ecs-app:name"
      values   = [var.app]
    }

    condition {
      test     = "StringEquals"
      variable = "ssm:ResourceTag/ecs-app:environment"
      values   = [var.environment]
    }
  }

  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:*"]

    condition {
      test     = "StringEquals"
      variable = "secretsmanager:ResourceTag/ecs-app:name"
      values   = [var.app]
    }

    condition {
      test     = "StringEquals"
      variable = "secretsmanager:ResourceTag/ecs-app:environment"
      values   = [var.environment]
    }
  }

  statement {
    actions   = ["kms:Decrypt"]
    resources = ["arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/*"]
  }
}

data "aws_iam_policy_document" "deny_iam_except_tagged_roles" {
  statement {
    effect    = "Deny"
    actions   = ["iam:*"]
    resources = ["*"]
  }

  statement {
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*"]

    condition {
      test     = "StringEquals"
      variable = "iam:ResourceTag/ecs-app:name"
      values   = [var.app]
    }

    condition {
      test     = "StringEquals"
      variable = "iam:ResourceTag/ecs-app:environment"
      values   = [var.environment]
    }
  }
}

data "aws_iam_policy_document" "state_machine" {
  statement {
    actions = ["iam:PassRole"]

    resources = [
      module.ecs_execution_role.this_iam_role_arn,
      module.ecs_task_role.this_iam_role_arn,
    ]
  }

  statement {
    actions   = ["ecs:RunTask"]
    resources = [aws_ecs_task_definition.this.arn]

    condition {
      test     = "ArnEquals"
      variable = "ecs:cluster"
      values   = ["arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${var.cluster}"]
    }
  }

  statement {
    actions = [
      "ecs:StopTask",
      "ecs:DescribeTasks",
    ]

    resources = ["*"]

    condition {
      test     = "ArnEquals"
      variable = "ecs:cluster"
      values   = ["arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${var.cluster}"]
    }
  }

  statement {
    actions = [
      "logs:CreateLogDelivery",
      "logs:GetLogDelivery",
      "logs:UpdateLogDelivery",
      "logs:DeleteLogDelivery",
      "logs:ListLogDeliveries",
      "logs:PutResourcePolicy",
      "logs:DescribeResourcePolicies",
      "logs:DescribeLogGroups",
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "events:PutTargets",
      "events:PutRule",
      "events:DescribeRule",
    ]

    resources = ["arn:aws:events:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:rule/StepFunctionsGetEventsForECSTaskRule"]
  }
}

data "aws_iam_policy_document" "event_rule" {
  statement {
    actions   = ["states:StartExecution"]
    resources = [aws_sfn_state_machine.this.id]
  }
}

resource "aws_iam_policy" "secrets" {
  name   = "${module.this_job_label.id}-SecretsPolicy"
  policy = data.aws_iam_policy_document.secrets.json
  path   = "/"
}

resource "aws_iam_policy" "deny_iam_except_tagged_roles" {
  name   = "${module.this_job_label.id}-DenyIAMExceptTaggedRolesPolicy"
  path   = "/"
  policy = data.aws_iam_policy_document.deny_iam_except_tagged_roles.json
}

resource "aws_iam_policy" "state_machine" {
  name   = "${local.name}-StateMachinePolicy"
  path   = "/"
  policy = data.aws_iam_policy_document.state_machine.json
}

resource "aws_iam_policy" "event_rule" {
  name   = "${local.name}-EventRuleRole"
  path   = "/"
  policy = data.aws_iam_policy_document.event_rule.json
}

module "this_ecs_execution_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 2.0"

  create_role = true

  trusted_role_services = ["ecs-tasks.amazonaws.com"]

  role_name         = "${module.this_job_label.id}-ExecutionRole"
  role_requires_mfa = false

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    aws_iam_policy.secrets.arn,
  ]

  tags = module.this_job_label.tags
}

module "ecs_task_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 2.0"

  create_role = true

  trusted_role_services = ["ecs-tasks.amazonaws.com"]

  role_name         = "${module.this_job_label.id}-TaskRole"
  role_requires_mfa = false

  custom_role_policy_arns = [aws_iam_policy.deny_iam_except_tagged_roles.arn]

  tags = module.this_job_label.tags
}

module "state_machine_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 2.0"

  create_role = true

  trusted_role_services = ["states.amazonaws.com"]

  role_name         = "${module.this_job_label.id}-StateMachineRole"
  role_requires_mfa = false

  custom_role_policy_arns = [aws_iam_policy.state_machine.arn]

  tags = module.this_job_label.tags
}

module "event_rule_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 2.0"

  create_role = true

  trusted_role_services = ["events.amazonaws.com"]

  role_name         = "${module.this_job_label.id}-EventRuleRole"
  role_requires_mfa = false

  custom_role_policy_arns = [aws_iam_policy.event_rule.arn]

  tags = module.this_job_label.tags
}
