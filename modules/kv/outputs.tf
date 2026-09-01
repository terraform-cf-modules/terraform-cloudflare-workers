output "enabled" {
  description = "Whether this submodule created its resources."
  value       = local.enabled
}

output "namespaces" {
  description = "Full cloudflare_workers_kv_namespace objects, keyed by the same keys as var.namespaces."
  value       = cloudflare_workers_kv_namespace.this
}

output "namespace_ids" {
  description = "Namespace ID of each created KV namespace, keyed by the same keys as var.namespaces."
  value       = { for k, v in cloudflare_workers_kv_namespace.this : k => v.id }
}

output "pairs" {
  description = "Full cloudflare_workers_kv objects, keyed by the same keys as var.pairs."
  value       = cloudflare_workers_kv.this
}

output "pair_ids" {
  description = "ID of each written KV pair, keyed by the same keys as var.pairs."
  value       = { for k, v in cloudflare_workers_kv.this : k => v.id }
}
