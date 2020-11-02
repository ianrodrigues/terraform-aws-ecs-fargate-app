variable "app" {
  type        = string
  description = "Name of the application, e.g. 'website' or 'ecommerce'"
}

variable "cluster_name" {
  type        = string
  description = "Name of an existing ECS cluster."
}

variable "container_extra_environment" {
  type = list(object({
    name  = string
    value = string
  }))

  description = "Extra environment variables to pass to the container."

  default = []
}

variable "container_extra_secrets" {
  type = list(object({
    name      = string
    valueFrom = string
  }))

  description = "Extra secrets to pass to the container."

  default = []
}

variable "container_image" {
  type        = string
  description = "The image used to start a container."
}

variable "cpu" {
  type        = number
  description = "Number of cpu units used by the task."
  default     = 256
}

variable "environment" {
  type        = string
  description = "Environment, e.g. 'prod', 'stag' or 'dev'"
}

variable "logs_retention_in_days" {
  type        = number
  description = "Specifies the number of days you want to retain log events in the specified log group."
  default     = 14
}

variable "memory" {
  type        = number
  description = "Amount (in MiB) of memory used by the task."
  default     = 512
}

variable "name" {
  type        = string
  description = "Name of the job or task, e.g. 'sells-report' or 'daily-backup'"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "A list of private Subnet IDs. It is required to defined either \"private_subnet_ids\" or \"public_subnet_ids\"."
  default     = []
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "A list of public Subnet IDs. It is required to defined either \"private_subnet_ids\" or \"public_subnet_ids\"."
  default     = []
}

variable "schedule_expression" {
  type        = string
  description = "The scheduling expression, e.g. 'cron(0 20 * * ? *) or 'rate(5 minutes)'"
}

variable "security_group_ids" {
  type        = list(string)
  description = "A list of Security Group IDs."
}
