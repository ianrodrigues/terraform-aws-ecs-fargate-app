variable "namespace" {
  type        = string
  description = "Organization name or abbreviation, e.g. 'foo' or 'bar'"
}

variable "name" {
  type        = string
  description = "Name of the application or service, e.g. 'nginx' or 'jenkins'"
}

variable "environment" {
  type        = string
  description = "Environment, e.g. 'prod', 'stag' or 'dev'"
}
