output "enabled" {
  description = "Whether this submodule created its resources."
  value       = local.enabled
}

output "buckets" {
  description = "Full cloudflare_r2_bucket objects, keyed by the same keys as var.buckets."
  value       = cloudflare_r2_bucket.this
}

output "bucket_ids" {
  description = "ID of each created R2 bucket, keyed by the same keys as var.buckets."
  value       = { for k, v in cloudflare_r2_bucket.this : k => v.id }
}

output "bucket_names" {
  description = "Name of each created R2 bucket, keyed by the same keys as var.buckets."
  value       = { for k, v in cloudflare_r2_bucket.this : k => v.name }
}

output "cors" {
  description = "Full cloudflare_r2_bucket_cors objects, keyed by bucket key."
  value       = cloudflare_r2_bucket_cors.this
}

output "lifecycle_rules" {
  description = "Full cloudflare_r2_bucket_lifecycle objects, keyed by bucket key."
  value       = cloudflare_r2_bucket_lifecycle.this
}

output "locks" {
  description = "Full cloudflare_r2_bucket_lock objects, keyed by bucket key."
  value       = cloudflare_r2_bucket_lock.this
}

output "event_notifications" {
  description = "Full cloudflare_r2_bucket_event_notification objects, keyed by \"<bucket key>/<notification key>\"."
  value       = cloudflare_r2_bucket_event_notification.this
}

output "custom_domains" {
  description = "Full cloudflare_r2_custom_domain objects, keyed by \"<bucket key>/<domain key>\"."
  value       = cloudflare_r2_custom_domain.this
}
