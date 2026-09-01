output "script_name" {
  description = "Name of the deployed Worker."
  value       = module.this.script_name
}

output "subdomain" {
  description = "workers.dev subdomain resource for the Worker."
  value       = module.this.subdomain
}
