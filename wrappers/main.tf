# -----------------------------------------------------------------------------
# Wrapper: create many Workers from a single map.
#
#   module "workers" {
#     source = "terraform-cf-modules/workers/cloudflare//wrappers"
#
#     defaults = {
#       account_id         = var.account_id
#       zone_id            = var.zone_id
#       compatibility_date = "2025-06-01"
#     }
#
#     items = {
#       api = {
#         script_name = "api"
#         content     = file("${path.module}/api.js")
#         routes      = { main = { pattern = "example.com/api/*" } }
#       }
#       cron = {
#         script_name    = "nightly"
#         content        = file("${path.module}/nightly.js")
#         cron_schedules = ["0 3 * * *"]
#       }
#     }
#   }
# -----------------------------------------------------------------------------

module "wrapper" {
  source = "../"

  for_each = var.items

  enabled    = try(each.value.enabled, var.defaults.enabled, true)
  account_id = try(each.value.account_id, var.defaults.account_id, null)
  zone_id    = try(each.value.zone_id, var.defaults.zone_id, null)

  script_name      = try(each.value.script_name, var.defaults.script_name, null)
  deployment_model = try(each.value.deployment_model, var.defaults.deployment_model, "script")

  content        = try(each.value.content, var.defaults.content, null)
  content_file   = try(each.value.content_file, var.defaults.content_file, null)
  content_sha256 = try(each.value.content_sha256, var.defaults.content_sha256, null)
  content_type   = try(each.value.content_type, var.defaults.content_type, null)
  main_module    = try(each.value.main_module, var.defaults.main_module, "worker.js")
  body_part      = try(each.value.body_part, var.defaults.body_part, null)
  modules        = try(each.value.modules, var.defaults.modules, {})

  compatibility_date  = try(each.value.compatibility_date, var.defaults.compatibility_date, null)
  compatibility_flags = try(each.value.compatibility_flags, var.defaults.compatibility_flags, null)

  logpush        = try(each.value.logpush, var.defaults.logpush, null)
  usage_model    = try(each.value.usage_model, var.defaults.usage_model, null)
  limits         = try(each.value.limits, var.defaults.limits, null)
  placement_mode = try(each.value.placement_mode, var.defaults.placement_mode, null)
  observability  = try(each.value.observability, var.defaults.observability, null)
  tail_consumers = try(each.value.tail_consumers, var.defaults.tail_consumers, {})
  migrations     = try(each.value.migrations, var.defaults.migrations, null)
  assets         = try(each.value.assets, var.defaults.assets, null)
  workers_dev    = try(each.value.workers_dev, var.defaults.workers_dev, null)
  keep_bindings  = try(each.value.keep_bindings, var.defaults.keep_bindings, null)
  worker_tags    = try(each.value.worker_tags, var.defaults.worker_tags, null)

  version_message    = try(each.value.version_message, var.defaults.version_message, null)
  version_tag        = try(each.value.version_tag, var.defaults.version_tag, null)
  deployment_message = try(each.value.deployment_message, var.defaults.deployment_message, null)

  bindings = try(each.value.bindings, var.defaults.bindings, {})

  routes         = try(each.value.routes, var.defaults.routes, {})
  custom_domains = try(each.value.custom_domains, var.defaults.custom_domains, {})
  cron_schedules = try(each.value.cron_schedules, var.defaults.cron_schedules, [])

  kv_namespaces      = try(each.value.kv_namespaces, var.defaults.kv_namespaces, {})
  kv_pairs           = try(each.value.kv_pairs, var.defaults.kv_pairs, {})
  d1_databases       = try(each.value.d1_databases, var.defaults.d1_databases, {})
  queues             = try(each.value.queues, var.defaults.queues, {})
  r2_buckets         = try(each.value.r2_buckets, var.defaults.r2_buckets, {})
  hyperdrive_configs = try(each.value.hyperdrive_configs, var.defaults.hyperdrive_configs, {})

  pages_projects = try(each.value.pages_projects, var.defaults.pages_projects, {})
  pages_domains  = try(each.value.pages_domains, var.defaults.pages_domains, {})
}
