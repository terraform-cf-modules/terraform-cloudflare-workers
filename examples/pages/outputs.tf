output "project_ids" {
  description = "IDs of the created Pages projects."
  value       = module.site.project_ids
}

output "project_subdomains" {
  description = "pages.dev subdomains of the created Pages projects."
  value       = module.site.project_subdomains
}

output "domain_ids" {
  description = "IDs of the custom domains attached to the Pages projects."
  value       = module.site.domain_ids
}
