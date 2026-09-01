output "enabled" {
  description = "Whether this submodule created its resources."
  value       = local.enabled
}

output "databases" {
  description = "Full cloudflare_d1_database objects, keyed by the same keys as var.databases."
  value       = cloudflare_d1_database.this
}

output "database_ids" {
  description = "UUID of each created D1 database, keyed by the same keys as var.databases."
  value       = { for k, v in cloudflare_d1_database.this : k => v.id }
}

output "database_names" {
  description = "Name of each created D1 database, keyed by the same keys as var.databases."
  value       = { for k, v in cloudflare_d1_database.this : k => v.name }
}
