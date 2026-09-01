output "script_name" {
  description = "Name of the deployed Worker."
  value       = module.this.script_name
}

output "kv_namespace_ids" {
  description = "IDs of the KV namespaces created for the Worker."
  value       = module.this.kv_namespace_ids
}

output "d1_database_ids" {
  description = "UUIDs of the D1 databases created for the Worker."
  value       = module.this.d1_database_ids
}

output "queue_ids" {
  description = "IDs of the queues created for the Worker."
  value       = module.this.queue_ids
}

output "r2_bucket_names" {
  description = "Names of the R2 buckets created for the Worker."
  value       = module.this.r2_bucket_names
}

output "hyperdrive_config_ids" {
  description = "IDs of the Hyperdrive configurations created for the Worker."
  value       = module.this.hyperdrive_config_ids
}

output "routes" {
  description = "Routes attached to the Worker."
  value       = module.this.routes
}

output "pages_project_subdomains" {
  description = "pages.dev subdomains of the created Pages projects."
  value       = module.this.pages_project_subdomains
}
