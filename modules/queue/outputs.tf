output "enabled" {
  description = "Whether this submodule created its resources."
  value       = local.enabled
}

output "queues" {
  description = "Full cloudflare_queue objects, keyed by the same keys as var.queues."
  value       = cloudflare_queue.this
}

output "queue_ids" {
  description = "Queue ID of each created queue, keyed by the same keys as var.queues."
  value       = { for k, v in cloudflare_queue.this : k => v.queue_id }
}

output "queue_names" {
  description = "Queue name of each created queue, keyed by the same keys as var.queues."
  value       = { for k, v in cloudflare_queue.this : k => v.queue_name }
}

output "consumers" {
  description = "Full cloudflare_queue_consumer objects, keyed by the same keys as var.consumers."
  value       = cloudflare_queue_consumer.this
}

output "consumer_ids" {
  description = "Consumer ID of each created queue consumer, keyed by the same keys as var.consumers."
  value       = { for k, v in cloudflare_queue_consumer.this : k => v.consumer_id }
}
