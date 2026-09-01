# -----------------------------------------------------------------------------
# Submodule: queue
#
# Cloudflare Queues and their consumers. A queue on its own only accepts
# producers; a consumer is what actually drains it.
# -----------------------------------------------------------------------------

locals {
  enabled = var.enabled

  queues    = local.enabled ? var.queues : {}
  consumers = local.enabled ? var.consumers : {}
}

resource "cloudflare_queue" "this" {
  for_each = local.queues

  account_id = var.account_id
  queue_name = each.value.queue_name

  settings = anytrue([
    each.value.delivery_delay != null,
    each.value.delivery_paused != null,
    each.value.message_retention_period != null,
    ]) ? {
    delivery_delay           = each.value.delivery_delay
    delivery_paused          = each.value.delivery_paused
    message_retention_period = each.value.message_retention_period
  } : null
}

resource "cloudflare_queue_consumer" "this" {
  for_each = local.consumers

  account_id        = var.account_id
  type              = each.value.type
  script_name       = each.value.script_name
  dead_letter_queue = each.value.dead_letter_queue

  queue_id = (
    each.value.queue_key != null
    ? cloudflare_queue.this[each.value.queue_key].queue_id
    : each.value.queue_id
  )

  settings = anytrue([
    each.value.batch_size != null,
    each.value.max_concurrency != null,
    each.value.max_retries != null,
    each.value.max_wait_time_ms != null,
    each.value.retry_delay != null,
    each.value.visibility_timeout_ms != null,
    ]) ? {
    batch_size            = each.value.batch_size
    max_concurrency       = each.value.max_concurrency
    max_retries           = each.value.max_retries
    max_wait_time_ms      = each.value.max_wait_time_ms
    retry_delay           = each.value.retry_delay
    visibility_timeout_ms = each.value.visibility_timeout_ms
  } : null
}
