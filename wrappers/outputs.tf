output "wrapper" {
  description = "Map of module outputs, keyed by the same keys as var.items."
  value       = module.wrapper
  sensitive   = true
}

output "script_names" {
  description = "Name of the Worker created for each item."
  value       = { for k, v in module.wrapper : k => v.script_name }
}
