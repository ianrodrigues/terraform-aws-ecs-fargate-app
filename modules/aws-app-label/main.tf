output "id" {
  description = "Disambiguated identifier"
  value       = "${lower(substr(var.namespace, 0, 3))}-${lower(substr(var.name, 0, 5))}-${lower(substr(var.environment, 0, 4))}"
}

output "tags" {
  description = "Normalized tag map"

  value = {
    "ecs-app:namespace"   = lower(var.namespace)
    "ecs-app:name"        = lower(var.name)
    "ecs-app:environment" = lower(var.environment)
  }
}
