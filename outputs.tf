output "enabled" {
  description = "Whether this module created its resources."
  value       = local.enabled
}

# -----------------------------------------------------------------------------
# Worker
# -----------------------------------------------------------------------------

output "script_name" {
  description = "Name of the deployed Worker, or null when script_name was not set."
  value       = module.script.script_name
}

output "script_id" {
  description = "ID of the deployed Worker."
  value       = module.script.id
}

output "script" {
  description = "Full cloudflare_workers_script object, or null in the versioned deployment model. Contains binding values."
  value       = module.script.script
  sensitive   = true
}

output "worker" {
  description = "Full cloudflare_worker object, or null in the script deployment model."
  value       = module.script.worker
}

output "worker_version" {
  description = "Full cloudflare_worker_version object, or null in the script deployment model."
  value       = module.script.worker_version
  sensitive   = true
}

output "deployment" {
  description = "Full cloudflare_workers_deployment object, or null in the script deployment model."
  value       = module.script.deployment
}

output "subdomain" {
  description = "Full cloudflare_workers_script_subdomain object, or null when workers_dev was not set."
  value       = module.script.subdomain
}

output "bindings" {
  description = "The binding map handed to the Worker, including the entries derived from the storage this module created."
  value       = local.bindings
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Routing and scheduling
# -----------------------------------------------------------------------------

output "routes" {
  description = "Full cloudflare_workers_route objects, keyed by the same keys as var.routes."
  value       = module.route.routes
}

output "custom_domains" {
  description = "Full cloudflare_workers_custom_domain objects, keyed by the same keys as var.custom_domains."
  value       = module.route.custom_domains
}

output "cron_triggers" {
  description = "Full cloudflare_workers_cron_trigger objects, keyed by the Worker name."
  value       = module.cron.triggers
}

# -----------------------------------------------------------------------------
# Storage
# -----------------------------------------------------------------------------

output "kv_namespaces" {
  description = "Full cloudflare_workers_kv_namespace objects, keyed by the same keys as var.kv_namespaces."
  value       = module.kv.namespaces
}

output "kv_namespace_ids" {
  description = "Namespace ID of each created KV namespace, keyed by the same keys as var.kv_namespaces."
  value       = module.kv.namespace_ids
}

output "kv_pairs" {
  description = "Full cloudflare_workers_kv objects, keyed by the same keys as var.kv_pairs."
  value       = module.kv.pairs
}

output "d1_databases" {
  description = "Full cloudflare_d1_database objects, keyed by the same keys as var.d1_databases."
  value       = module.d1.databases
}

output "d1_database_ids" {
  description = "UUID of each created D1 database, keyed by the same keys as var.d1_databases."
  value       = module.d1.database_ids
}

output "queues" {
  description = "Full cloudflare_queue objects, keyed by the same keys as var.queues."
  value       = module.queue.queues
}

output "queue_ids" {
  description = "Queue ID of each created queue, keyed by the same keys as var.queues."
  value       = module.queue.queue_ids
}

output "queue_consumers" {
  description = "Full cloudflare_queue_consumer objects, keyed by the same keys as var.queues."
  value       = module.queue.consumers
}

output "r2_buckets" {
  description = "Full cloudflare_r2_bucket objects, keyed by the same keys as var.r2_buckets."
  value       = module.r2.buckets
}

output "r2_bucket_names" {
  description = "Name of each created R2 bucket, keyed by the same keys as var.r2_buckets."
  value       = module.r2.bucket_names
}

output "r2_custom_domains" {
  description = "Full cloudflare_r2_custom_domain objects, keyed by \"<bucket key>/<domain key>\"."
  value       = module.r2.custom_domains
}

output "hyperdrive_configs" {
  description = "Full cloudflare_hyperdrive_config objects, keyed by the same keys as var.hyperdrive_configs. Contains origin credentials."
  value       = module.hyperdrive.configs
  sensitive   = true
}

output "hyperdrive_config_ids" {
  description = "ID of each created Hyperdrive configuration, keyed by the same keys as var.hyperdrive_configs."
  value       = module.hyperdrive.config_ids
}

# -----------------------------------------------------------------------------
# Pages
# -----------------------------------------------------------------------------

output "pages_projects" {
  description = "Full cloudflare_pages_project objects, keyed by the same keys as var.pages_projects."
  value       = module.pages.projects
  sensitive   = true
}

output "pages_project_subdomains" {
  description = "The pages.dev subdomain of each created Pages project."
  value       = module.pages.project_subdomains
}

output "pages_domains" {
  description = "Full cloudflare_pages_domain objects, keyed by the same keys as var.pages_domains."
  value       = module.pages.domains
}
