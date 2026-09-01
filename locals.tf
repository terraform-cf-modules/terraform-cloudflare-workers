locals {
  # Single switch consulted by every resource in this module.
  enabled = var.enabled

  # The Worker itself is optional: the module is also useful for creating the storage side on its own.
  create_script = local.enabled && var.script_name != null

  # ---------------------------------------------------------------------------
  # Derived bindings
  #
  # This is the reason the module exists. Each storage entry that names a
  # `binding` turns into the binding object the Workers API expects, wired to
  # the resource this module just created. KV and D1 bind by ID, so the value is
  # only known after apply; R2 and Queues bind by name, so the value comes
  # straight from the input.
  # ---------------------------------------------------------------------------

  kv_bindings = {
    for k, v in var.kv_namespaces : v.binding => {
      type         = "kv_namespace"
      namespace_id = module.kv.namespace_ids[k]
    } if local.enabled && v.binding != null
  }

  d1_bindings = {
    for k, v in var.d1_databases : v.binding => {
      type        = "d1"
      database_id = module.d1.database_ids[k]
    } if local.enabled && v.binding != null
  }

  queue_bindings = {
    for k, v in var.queues : v.binding => {
      type       = "queue"
      queue_name = module.queue.queue_names[k]
    } if local.enabled && v.binding != null
  }

  r2_bindings = {
    for k, v in var.r2_buckets : v.binding => {
      type         = "r2_bucket"
      bucket_name  = module.r2.bucket_names[k]
      jurisdiction = v.jurisdiction
    } if local.enabled && v.binding != null
  }

  hyperdrive_bindings = {
    for k, v in var.hyperdrive_configs : v.binding => {
      type = "hyperdrive"
      id   = module.hyperdrive.config_ids[k]
    } if local.enabled && v.binding != null
  }

  bindings = merge(
    local.kv_bindings,
    local.d1_bindings,
    local.queue_bindings,
    local.r2_bindings,
    local.hyperdrive_bindings,
    var.bindings,
  )

  # ---------------------------------------------------------------------------
  # Routing and scheduling
  #
  # These reference module.script.script_name rather than var.script_name so
  # Terraform orders them after the upload. The value is the same either way.
  # ---------------------------------------------------------------------------

  routes = {
    for k, r in var.routes : k => {
      pattern = r.pattern
      zone_id = r.zone_id
      script  = coalesce(r.script, module.script.script_name)
    } if local.create_script || r.script != null
  }

  custom_domains = {
    for k, d in var.custom_domains : k => {
      hostname  = d.hostname
      zone_id   = d.zone_id
      zone_name = d.zone_name
      service   = coalesce(d.service, module.script.script_name)
    } if local.create_script || d.service != null
  }

  cron_triggers = local.create_script && length(var.cron_schedules) > 0 ? {
    (var.script_name) = {
      script_name = module.script.script_name
      schedules   = var.cron_schedules
    }
  } : {}

  # ---------------------------------------------------------------------------
  # Queue consumers declared inline on a queue entry
  # ---------------------------------------------------------------------------

  queue_consumers = {
    for k, q in var.queues : k => {
      type                  = q.consumer.type
      queue_key             = k
      queue_id              = null
      script_name           = q.consumer.type == "worker" ? coalesce(q.consumer.script_name, module.script.script_name) : q.consumer.script_name
      dead_letter_queue     = q.consumer.dead_letter_queue
      batch_size            = q.consumer.batch_size
      max_concurrency       = q.consumer.max_concurrency
      max_retries           = q.consumer.max_retries
      max_wait_time_ms      = q.consumer.max_wait_time_ms
      retry_delay           = q.consumer.retry_delay
      visibility_timeout_ms = q.consumer.visibility_timeout_ms
    } if q.consumer != null && (q.consumer.type != "worker" || local.create_script || q.consumer.script_name != null)
  }
}
