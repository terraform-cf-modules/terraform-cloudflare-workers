output "enabled" {
  description = "Whether this submodule created its resources."
  value       = local.enabled
}

output "projects" {
  description = "Full cloudflare_pages_project objects, keyed by the same keys as var.projects. Contains environment variable values."
  value       = cloudflare_pages_project.this
  sensitive   = true
}

output "project_ids" {
  description = "ID of each created Pages project, keyed by the same keys as var.projects."
  value       = { for k, v in cloudflare_pages_project.this : k => v.id }
}

output "project_subdomains" {
  description = "The pages.dev subdomain of each created Pages project, keyed by the same keys as var.projects."
  value       = { for k, v in cloudflare_pages_project.this : k => v.subdomain }
}

output "domains" {
  description = "Full cloudflare_pages_domain objects, keyed by the same keys as var.domains."
  value       = cloudflare_pages_domain.this
}

output "domain_ids" {
  description = "ID of each created Pages domain, keyed by the same keys as var.domains."
  value       = { for k, v in cloudflare_pages_domain.this : k => v.id }
}
