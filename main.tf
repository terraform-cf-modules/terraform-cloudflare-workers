# -----------------------------------------------------------------------------
# Module: Cloudflare Workers
# Workers, routes, cron triggers, and the developer platform storage bindings
# (KV, D1, Queues, R2, Hyperdrive) plus Pages.
#
# Root module composes the common case: create the storage a Worker needs,
# derive the bindings, upload the Worker, then attach routes and schedules.
# Individual building blocks live under modules/ and are consumed with the
# double slash source syntax:
#
#   source = "terraform-cf-modules/workers/cloudflare//modules/<name>"
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Storage. Created first so the Worker can be bound to it.
# -----------------------------------------------------------------------------

module "kv" {
  source = "./modules/kv"

  enabled    = local.enabled
  account_id = var.account_id

  namespaces = { for k, v in var.kv_namespaces : k => { title = v.title } }
  pairs      = var.kv_pairs
}

module "d1" {
  source = "./modules/d1"

  enabled    = local.enabled
  account_id = var.account_id

  databases = {
    for k, v in var.d1_databases : k => {
      name                  = v.name
      primary_location_hint = v.primary_location_hint
      jurisdiction          = v.jurisdiction
      read_replication_mode = v.read_replication_mode
    }
  }
}

module "queue" {
  source = "./modules/queue"

  enabled    = local.enabled
  account_id = var.account_id

  queues = {
    for k, v in var.queues : k => {
      queue_name               = v.queue_name
      delivery_delay           = v.delivery_delay
      delivery_paused          = v.delivery_paused
      message_retention_period = v.message_retention_period
    }
  }

  consumers = local.queue_consumers
}

module "r2" {
  source = "./modules/r2"

  enabled    = local.enabled
  account_id = var.account_id

  buckets = {
    for k, v in var.r2_buckets : k => {
      name                = v.name
      location            = v.location
      jurisdiction        = v.jurisdiction
      storage_class       = v.storage_class
      cors_rules          = v.cors_rules
      lifecycle_rules     = v.lifecycle_rules
      lock_rules          = v.lock_rules
      event_notifications = v.event_notifications
      custom_domains      = v.custom_domains
    }
  }
}

module "hyperdrive" {
  source = "./modules/hyperdrive"

  enabled    = local.enabled
  account_id = var.account_id

  configs = {
    for k, v in var.hyperdrive_configs : k => {
      name                    = v.name
      origin                  = v.origin
      origin_connection_limit = v.origin_connection_limit
      caching                 = v.caching
      mtls                    = v.mtls
    }
  }
}

# -----------------------------------------------------------------------------
# The Worker. Its bindings reference the storage above, which is what orders
# these module calls without any depends_on.
# -----------------------------------------------------------------------------

module "script" {
  source = "./modules/script"

  enabled          = local.create_script
  account_id       = var.account_id
  script_name      = var.script_name
  deployment_model = var.deployment_model

  content        = var.content
  content_file   = var.content_file
  content_sha256 = var.content_sha256
  content_type   = var.content_type
  main_module    = var.body_part != null ? null : var.main_module
  body_part      = var.body_part
  modules        = var.modules

  compatibility_date  = var.compatibility_date
  compatibility_flags = var.compatibility_flags

  bindings      = local.bindings
  keep_bindings = var.keep_bindings

  logpush        = var.logpush
  usage_model    = var.usage_model
  limits         = var.limits
  placement_mode = var.placement_mode
  observability  = var.observability
  tail_consumers = var.tail_consumers
  migrations     = var.migrations
  assets         = var.assets
  workers_dev    = var.workers_dev

  worker_tags        = var.worker_tags
  version_message    = var.version_message
  version_tag        = var.version_tag
  deployment_message = var.deployment_message
}

# -----------------------------------------------------------------------------
# Triggers
# -----------------------------------------------------------------------------

module "route" {
  source = "./modules/route"

  enabled    = local.enabled
  account_id = var.account_id
  zone_id    = var.zone_id

  routes         = local.routes
  custom_domains = local.custom_domains
}

module "cron" {
  source = "./modules/cron"

  enabled    = local.enabled
  account_id = var.account_id

  triggers = local.cron_triggers
}

# -----------------------------------------------------------------------------
# Pages. Independent of the Worker above, but shares the same storage products.
# -----------------------------------------------------------------------------

module "pages" {
  source = "./modules/pages"

  enabled    = local.enabled
  account_id = var.account_id

  projects = var.pages_projects
  domains  = var.pages_domains
}
