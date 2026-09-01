output "enabled" {
  description = "Whether this submodule created its resources."
  value       = local.enabled
}

output "deployment_model" {
  description = "Which provider resources back the Worker: script or versioned."
  value       = var.deployment_model
}

output "script_name" {
  description = "Name of the Worker, read back from the resource so dependent resources order correctly."
  value = try(coalesce(
    one(cloudflare_workers_script.this[*].script_name),
    one(cloudflare_worker.this[*].name),
  ), null)
}

output "id" {
  description = "ID of the Worker. The script name in the script model, the immutable Worker ID in the versioned model."
  value = try(coalesce(
    one(cloudflare_workers_script.this[*].id),
    one(cloudflare_worker.this[*].id),
  ), null)
}

output "script" {
  description = "Full cloudflare_workers_script object, or null in the versioned model. Contains binding values."
  value       = one(cloudflare_workers_script.this)
  sensitive   = true
}

output "worker" {
  description = "Full cloudflare_worker object, or null in the script model."
  value       = one(cloudflare_worker.this)
}

output "worker_version" {
  description = "Full cloudflare_worker_version object, or null in the script model. Contains binding values."
  value       = one(cloudflare_worker_version.this)
  sensitive   = true
}

output "deployment" {
  description = "Full cloudflare_workers_deployment object, or null in the script model."
  value       = one(cloudflare_workers_deployment.this)
}

output "subdomain" {
  description = "Full cloudflare_workers_script_subdomain object, or null when workers_dev was not set."
  value       = one(cloudflare_workers_script_subdomain.this)
}

output "workers_dev_url" {
  description = "The workers.dev address the Worker serves on, when the versioned model reports one."
  value       = try(one(cloudflare_worker.this[*].subdomain.url), null)
}

output "etag" {
  description = "Etag of the uploaded script, or null in the versioned model."
  value       = try(one(cloudflare_workers_script.this[*].etag), null)
}
