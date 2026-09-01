# -----------------------------------------------------------------------------
# Submodule: script
#
# The Worker itself. Two shapes are available, selected by var.deployment_model:
#
#   script     cloudflare_workers_script (+ cloudflare_workers_script_subdomain)
#   versioned  cloudflare_worker + cloudflare_worker_version + cloudflare_workers_deployment
#
# Both accept the same bindings map. See docs/architecture.md for the trade off.
# -----------------------------------------------------------------------------

locals {
  # A Worker with no name is not a Worker, so an unset script_name disables the submodule outright.
  enabled = var.enabled && var.script_name != null

  use_script    = local.enabled && var.deployment_model == "script"
  use_versioned = local.enabled && var.deployment_model == "versioned"

  # The provider takes bindings as a list of objects with an inline `name`. Callers give a map keyed by that
  # name, which keeps the plan diff stable when bindings are added or removed.
  bindings = length(var.bindings) == 0 ? null : [
    for name, b in var.bindings : merge(b, { name = name })
  ]

  tail_consumers = length(var.tail_consumers) == 0 ? null : [
    for k, t in var.tail_consumers : {
      service     = t.service
      environment = t.environment
      namespace   = t.namespace
    }
  ]

  worker_tail_consumers = length(var.tail_consumers) == 0 ? null : [
    for k, t in var.tail_consumers : { name = t.service }
  ]

  placement = var.placement_mode == null ? null : { mode = var.placement_mode }

  migrations = var.migrations == null ? null : {
    old_tag            = var.migrations.old_tag
    new_tag            = var.migrations.new_tag
    new_classes        = var.migrations.new_classes
    new_sqlite_classes = var.migrations.new_sqlite_classes
    deleted_classes    = var.migrations.deleted_classes
    renamed_classes = [
      for k, c in var.migrations.renamed_classes : { from = c.from, to = c.to }
    ]
    transferred_classes = [
      for k, c in var.migrations.transferred_classes : {
        from        = c.from
        from_script = c.from_script
        to          = c.to
      }
    ]
  }

  # cloudflare_worker_version has no inline `content`: code is uploaded as named modules. When the caller passed
  # inline content, wrap it as the entrypoint module so both deployment models take the same inputs.
  inline_module = var.content == null || var.main_module == null ? {} : {
    (var.main_module) = {
      content_type   = coalesce(var.content_type, "application/javascript+module")
      content_base64 = base64encode(var.content)
      content_file   = null
    }
  }

  version_modules = merge(
    local.inline_module,
    {
      for k, m in var.modules : coalesce(m.module_name, k) => {
        content_type   = m.content_type
        content_base64 = m.content_base64
        content_file   = m.content_file
      }
    }
  )
}

# -----------------------------------------------------------------------------
# Deployment model: script
# -----------------------------------------------------------------------------

resource "cloudflare_workers_script" "this" {
  count = local.use_script ? 1 : 0

  account_id  = var.account_id
  script_name = var.script_name

  content        = var.content
  content_file   = var.content_file
  content_sha256 = var.content_sha256
  content_type   = var.content_type
  main_module    = var.main_module
  body_part      = var.body_part

  compatibility_date  = var.compatibility_date
  compatibility_flags = var.compatibility_flags

  bindings      = local.bindings
  keep_bindings = var.keep_bindings

  logpush     = var.logpush
  usage_model = var.usage_model

  limits         = var.limits
  placement      = local.placement
  observability  = var.observability
  tail_consumers = local.tail_consumers
  migrations     = local.migrations
  assets         = var.assets
}

resource "cloudflare_workers_script_subdomain" "this" {
  count = local.use_script && var.workers_dev != null ? 1 : 0

  account_id       = var.account_id
  script_name      = cloudflare_workers_script.this[0].script_name
  enabled          = var.workers_dev.enabled
  previews_enabled = var.workers_dev.previews_enabled
}

# -----------------------------------------------------------------------------
# Deployment model: versioned
# -----------------------------------------------------------------------------

resource "cloudflare_worker" "this" {
  count = local.use_versioned ? 1 : 0

  account_id = var.account_id
  name       = var.script_name
  logpush    = var.logpush
  tags       = var.worker_tags

  observability  = var.observability
  tail_consumers = local.worker_tail_consumers

  subdomain = var.workers_dev == null ? null : {
    enabled          = var.workers_dev.enabled
    previews_enabled = var.workers_dev.previews_enabled
  }
}

resource "cloudflare_worker_version" "this" {
  count = local.use_versioned ? 1 : 0

  account_id = var.account_id
  worker_id  = cloudflare_worker.this[0].id

  main_module         = var.main_module
  compatibility_date  = var.compatibility_date
  compatibility_flags = var.compatibility_flags

  bindings   = local.bindings
  limits     = var.limits
  placement  = local.placement
  migrations = local.migrations
  assets     = var.assets

  modules = length(local.version_modules) == 0 ? null : [
    for name, m in local.version_modules : {
      name           = name
      content_type   = m.content_type
      content_base64 = m.content_base64
      content_file   = m.content_file
    }
  ]

  annotations = var.version_message == null && var.version_tag == null ? null : {
    workers_message = var.version_message
    workers_tag     = var.version_tag
  }
}

resource "cloudflare_workers_deployment" "this" {
  count = local.use_versioned ? 1 : 0

  account_id  = var.account_id
  script_name = cloudflare_worker.this[0].name
  strategy    = "percentage"

  versions = [{
    version_id = cloudflare_worker_version.this[0].id
    percentage = 100
  }]

  annotations = var.deployment_message == null ? null : {
    workers_message = var.deployment_message
  }
}
