output "enabled" {
  description = "Whether this submodule created its resources."
  value       = local.enabled
}

output "routes" {
  description = "Full cloudflare_workers_route objects, keyed by the same keys as var.routes."
  value       = cloudflare_workers_route.this
}

output "route_ids" {
  description = "ID of each created route, keyed by the same keys as var.routes."
  value       = { for k, v in cloudflare_workers_route.this : k => v.id }
}

output "custom_domains" {
  description = "Full cloudflare_workers_custom_domain objects, keyed by the same keys as var.custom_domains."
  value       = cloudflare_workers_custom_domain.this
}

output "custom_domain_ids" {
  description = "ID of each created custom domain, keyed by the same keys as var.custom_domains."
  value       = { for k, v in cloudflare_workers_custom_domain.this : k => v.id }
}
