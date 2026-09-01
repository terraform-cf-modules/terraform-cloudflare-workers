output "enabled" {
  description = "Whether this submodule created its resources."
  value       = local.enabled
}

output "configs" {
  description = "Full cloudflare_hyperdrive_config objects, keyed by the same keys as var.configs. Contains the origin credentials."
  value       = cloudflare_hyperdrive_config.this
  sensitive   = true
}

output "config_ids" {
  description = "ID of each created Hyperdrive configuration, keyed by the same keys as var.configs."
  value       = { for k, v in cloudflare_hyperdrive_config.this : k => v.id }
}
