variable "capacity_providers" {
  type        = list(string)
  description = "List of short names of one or more capacity providers to associate with the cluster."
  default     = ["FARGATE", "FARGATE_SPOT"]
}

variable "create_load_balancer" {
  type        = bool
  description = "Whether to create an Application Load Balancer (ALB)."
  default     = true
}

variable "default_capacity_provider_strategies" {
  type = list(object({
    capacity_provider = string
    weight            = number
    base              = number
  }))

  description = "The capacity provider strategy to use by default for the cluster."

  default = []
}

variable "enable_container_insights" {
  type        = bool
  description = "Whether to enable ECS Container Insights."
  default     = true
}

variable "environment" {
  type        = string
  description = "Environment, e.g. 'prod', 'stag' or 'dev'"
}

variable "name" {
  type        = string
  description = "Name of the application or service, e.g. 'nginx' or 'jenkins'"
}

variable "namespace" {
  type        = string
  description = "Organization name or abbreviation, e.g. 'foo' or 'bar'"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "A list of public Subnet IDs. It must be set if \"create_load_balancer\" is \"true\"."
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Key-value map of resource tags."
  default     = {}
}

variable "vpc_id" {
  type        = string
  description = "The VPC ID."
}
