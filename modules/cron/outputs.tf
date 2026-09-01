output "enabled" {
  description = "Whether this submodule created its resources."
  value       = local.enabled
}

output "triggers" {
  description = "Full cloudflare_workers_cron_trigger objects, keyed by the same keys as var.triggers."
  value       = cloudflare_workers_cron_trigger.this
}

output "trigger_ids" {
  description = "ID of each created cron trigger, keyed by the same keys as var.triggers."
  value       = { for k, v in cloudflare_workers_cron_trigger.this : k => v.id }
}
