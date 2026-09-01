# -----------------------------------------------------------------------------
# Common inputs. Every module in this organisation exposes these.
# -----------------------------------------------------------------------------

variable "enabled" {
  description = "Whether to create the resources managed by this module. Set to false to disable the module without removing the block."
  type        = bool
  default     = true
}

variable "account_id" {
  description = "Cloudflare account ID that owns the resources. Required for account scoped resources."
  type        = string
  default     = null

  validation {
    condition     = var.account_id == null || can(regex("^[0-9a-f]{32}$", var.account_id))
    error_message = "account_id must be a 32 character lowercase hexadecimal Cloudflare account ID."
  }
}

variable "zone_id" {
  description = "Cloudflare zone ID that owns the resources. Required for zone scoped resources."
  type        = string
  default     = null

  validation {
    condition     = var.zone_id == null || can(regex("^[0-9a-f]{32}$", var.zone_id))
    error_message = "zone_id must be a 32 character lowercase hexadecimal Cloudflare zone ID."
  }
}

# -----------------------------------------------------------------------------
# The Worker
# -----------------------------------------------------------------------------

variable "script_name" {
  description = "Name of the Worker to deploy. Leave null to create only the storage resources and skip the Worker."
  type        = string
  default     = null

  validation {
    condition     = var.script_name == null || can(regex("^[a-z0-9][a-z0-9_-]{0,62}$", coalesce(var.script_name, "x")))
    error_message = "script_name must start with a lowercase letter or digit and contain only lowercase letters, digits, dashes and underscores, up to 63 characters."
  }
}

variable "deployment_model" {
  description = <<-EOT
    Which provider resources back the Worker.

      * `script`    - a single `cloudflare_workers_script`. Stable and generally available. The default.
      * `versioned` - `cloudflare_worker` plus `cloudflare_worker_version` plus `cloudflare_workers_deployment`.
                      Beta in the provider. Use it when you need versions and gradual deployments.

    docs/architecture.md explains the trade off.
  EOT
  type        = string
  default     = "script"

  validation {
    condition     = contains(["script", "versioned"], var.deployment_model)
    error_message = "deployment_model must be either script or versioned."
  }
}

variable "content" {
  description = "Worker source code, inline. Mutually exclusive with content_file."
  type        = string
  default     = null
}

variable "content_file" {
  description = "Path to a file holding the Worker source code. Mutually exclusive with content."
  type        = string
  default     = null
}

variable "content_sha256" {
  description = "SHA-256 of the Worker source. Set it alongside content_file so Terraform notices changes to the file."
  type        = string
  default     = null
}

variable "content_type" {
  description = "Content type of the uploaded module, for example application/javascript+module."
  type        = string
  default     = null
}

variable "main_module" {
  description = "Entrypoint module name for an ES module Worker, for example worker.js."
  type        = string
  default     = "worker.js"
}

variable "body_part" {
  description = "Entrypoint part name for a legacy service worker format Worker. Mutually exclusive with main_module."
  type        = string
  default     = null
}

variable "modules" {
  description = "Extra modules uploaded alongside the entrypoint, keyed by module name. Only used when deployment_model is `versioned`."
  type = map(object({
    content_type   = string
    content_file   = optional(string)
    content_base64 = optional(string)
    module_name    = optional(string)
  }))
  default = {}
}

variable "compatibility_date" {
  description = "Runtime compatibility date, for example 2025-01-01."
  type        = string
  default     = null
}

variable "compatibility_flags" {
  description = "Runtime compatibility flags, for example [\"nodejs_compat\"]."
  type        = set(string)
  default     = null
}

variable "logpush" {
  description = "Whether Workers Logpush is enabled for the Worker."
  type        = bool
  default     = null
}

variable "usage_model" {
  description = "Billing usage model for the Worker."
  type        = string
  default     = null

  validation {
    condition     = var.usage_model == null || contains(["standard", "bundled", "unbound"], coalesce(var.usage_model, "standard"))
    error_message = "usage_model must be one of standard, bundled, unbound."
  }
}

variable "limits" {
  description = "CPU and subrequest limits for the Worker."
  type = object({
    cpu_ms      = optional(number)
    subrequests = optional(number)
  })
  default = null
}

variable "placement_mode" {
  description = "Smart Placement mode. Leave null to keep the default placement."
  type        = string
  default     = null

  validation {
    condition     = var.placement_mode == null || contains(["smart", "targeted"], coalesce(var.placement_mode, "smart"))
    error_message = "placement_mode must be either smart or targeted."
  }
}

variable "observability" {
  description = "Workers observability settings. `enabled` turns on the feature; the nested logs and traces objects tune each stream."
  type = object({
    enabled            = bool
    head_sampling_rate = optional(number)
    logs = optional(object({
      enabled            = bool
      invocation_logs    = bool
      destinations       = optional(list(string))
      head_sampling_rate = optional(number)
      persist            = optional(bool)
    }))
    traces = optional(object({
      enabled            = optional(bool)
      destinations       = optional(list(string))
      head_sampling_rate = optional(number)
      persist            = optional(bool)
      propagation_policy = optional(string)
    }))
  })
  default = null
}

variable "tail_consumers" {
  description = "Other Workers that receive this Worker's tail events, keyed by a stable identifier."
  type = map(object({
    service     = string
    environment = optional(string)
    namespace   = optional(string)
  }))
  default = {}
}

variable "migrations" {
  description = "Durable Object class migrations applied on upload."
  type = object({
    old_tag            = optional(string)
    new_tag            = optional(string)
    new_classes        = optional(list(string))
    new_sqlite_classes = optional(list(string))
    deleted_classes    = optional(list(string))
    renamed_classes = optional(map(object({
      from = string
      to   = string
    })), {})
    transferred_classes = optional(map(object({
      from        = string
      from_script = string
      to          = string
    })), {})
  })
  default = null
}

variable "assets" {
  description = "Static assets served in front of the Worker. `directory` is a path on the machine running Terraform."
  type = object({
    directory = optional(string)
    jwt       = optional(string)
    config = optional(object({
      headers            = optional(string)
      redirects          = optional(string)
      html_handling      = optional(string)
      not_found_handling = optional(string)
      run_worker_first   = optional(any)
    }))
  })
  default = null
}

variable "workers_dev" {
  description = "workers.dev subdomain settings. Leave null to leave the subdomain untouched."
  type = object({
    enabled          = bool
    previews_enabled = optional(bool)
  })
  default = null
}

variable "keep_bindings" {
  description = "Binding types to carry over from the deployed Worker rather than replace, for example [\"secret_text\"]."
  type        = set(string)
  default     = null
}

variable "worker_tags" {
  description = "Tags attached to the Worker. Only used when deployment_model is `versioned`."
  type        = set(string)
  default     = null
}

variable "version_message" {
  description = "Human readable message recorded against the uploaded version. Only used when deployment_model is `versioned`."
  type        = string
  default     = null
}

variable "version_tag" {
  description = "Caller supplied identifier recorded against the uploaded version. Only used when deployment_model is `versioned`."
  type        = string
  default     = null
}

variable "deployment_message" {
  description = "Human readable message recorded against the deployment. Only used when deployment_model is `versioned`."
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Bindings
# -----------------------------------------------------------------------------

variable "bindings" {
  description = <<-EOT
    Extra Worker bindings that this module does not derive automatically, keyed by the variable name the Worker
    sees. Storage created through `kv_namespaces`, `d1_databases`, `queues`, `r2_buckets` and `hyperdrive_configs`
    is bound for you; use this map for `plain_text`, `json`, `service`, `durable_object_namespace`, `ai`,
    `browser`, `vectorize` and anything else.

    See modules/script/README.md for the field each binding type expects.
  EOT
  type = map(object({
    type = string

    algorithm                     = optional(string)
    allowed_destination_addresses = optional(list(string))
    allowed_sender_addresses      = optional(list(string))
    app_id                        = optional(string)
    bucket_name                   = optional(string)
    certificate_id                = optional(string)
    class_name                    = optional(string)
    database_id                   = optional(string)
    dataset                       = optional(string)
    destination_address           = optional(string)
    dispatch_namespace            = optional(string)
    entrypoint                    = optional(string)
    environment                   = optional(string)
    format                        = optional(string)
    id                            = optional(string)
    index_name                    = optional(string)
    instance_name                 = optional(string)
    json                          = optional(string)
    jurisdiction                  = optional(string)
    key_base64                    = optional(string)
    key_jwk                       = optional(string)
    namespace                     = optional(string)
    namespace_id                  = optional(string)
    network_id                    = optional(string)
    old_name                      = optional(string)
    part                          = optional(string)
    pipeline                      = optional(string)
    queue_name                    = optional(string)
    script_name                   = optional(string)
    secret_name                   = optional(string)
    service                       = optional(string)
    service_id                    = optional(string)
    store_id                      = optional(string)
    text                          = optional(string)
    tunnel_id                     = optional(string)
    usages                        = optional(set(string))
    version_id                    = optional(string)
    workflow_name                 = optional(string)

    outbound = optional(object({
      params = optional(list(string))
      worker = optional(object({
        environment = optional(string)
        service     = optional(string)
      }))
    }))

    simple = optional(object({
      limit              = number
      period             = number
      mitigation_timeout = optional(number)
    }))
  }))
  default = {}

  validation {
    condition     = alltrue([for k in keys(var.bindings) : can(regex("^[A-Za-z_$][A-Za-z0-9_$]*$", k))])
    error_message = "Each binding key becomes the JavaScript variable name the Worker sees, so it must be a valid JavaScript identifier."
  }

  # Cross variable validation, supported since Terraform 1.9. A collision here would otherwise be silent: the
  # derived binding and the explicit one share a key and merge() would keep only one of them.
  validation {
    condition = length(setintersection(
      toset(keys(var.bindings)),
      toset(compact(concat(
        [for v in values(var.kv_namespaces) : v.binding == null ? "" : v.binding],
        [for v in values(var.d1_databases) : v.binding == null ? "" : v.binding],
        [for v in values(var.queues) : v.binding == null ? "" : v.binding],
        [for v in values(var.r2_buckets) : v.binding == null ? "" : v.binding],
        [for v in values(var.hyperdrive_configs) : v.binding == null ? "" : v.binding],
      ))),
    )) == 0
    error_message = "A key in var.bindings collides with a binding name derived from kv_namespaces, d1_databases, queues, r2_buckets or hyperdrive_configs. Binding names must be unique."
  }
}

# -----------------------------------------------------------------------------
# Routing
# -----------------------------------------------------------------------------

variable "routes" {
  description = <<-EOT
    Worker routes, keyed by a stable identifier. `script` defaults to the Worker this module deploys, so a route
    usually only needs a pattern.
  EOT
  type = map(object({
    pattern = string
    script  = optional(string)
    zone_id = optional(string)
  }))
  default = {}
}

variable "custom_domains" {
  description = <<-EOT
    Worker custom domains, keyed by a stable identifier. `service` defaults to the Worker this module deploys.
  EOT
  type = map(object({
    hostname  = string
    service   = optional(string)
    zone_id   = optional(string)
    zone_name = optional(string)
  }))
  default = {}
}

variable "cron_schedules" {
  description = <<-EOT
    Cron schedules that invoke this Worker's scheduled handler, in UTC. Five field cron expressions, or one of
    @hourly, @daily, @weekly, @monthly, @yearly. Empty means no cron trigger.
  EOT
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Storage: created here and bound to the Worker automatically
# -----------------------------------------------------------------------------

variable "kv_namespaces" {
  description = <<-EOT
    Workers KV namespaces to create, keyed by a stable identifier. Set `binding` to the variable name the Worker
    should see, or leave it null to create the namespace without binding it.
  EOT
  type = map(object({
    title   = string
    binding = optional(string)
  }))
  default = {}
}

variable "kv_pairs" {
  description = <<-EOT
    Key/value pairs written into the namespaces above, keyed by a stable identifier. `namespace_key` references a
    key in var.kv_namespaces; `namespace_id` targets a namespace created elsewhere.

    Values are stored in Terraform state in plain text.
  EOT
  type = map(object({
    key_name      = string
    value         = string
    namespace_key = optional(string)
    namespace_id  = optional(string)
    metadata      = optional(string)
  }))
  default = {}
}

variable "d1_databases" {
  description = <<-EOT
    D1 databases to create, keyed by a stable identifier. Set `binding` to the variable name the Worker should
    see, or leave it null to create the database without binding it.
  EOT
  type = map(object({
    name                  = string
    primary_location_hint = optional(string)
    jurisdiction          = optional(string)
    read_replication_mode = optional(string)
    binding               = optional(string)
  }))
  default = {}
}

variable "queues" {
  description = <<-EOT
    Cloudflare Queues to create, keyed by a stable identifier.

    `binding` gives the Worker a producer binding for the queue. `consumer` additionally registers a consumer;
    leave `consumer.script_name` null to make the Worker this module deploys the consumer.
  EOT
  type = map(object({
    queue_name               = string
    delivery_delay           = optional(number)
    delivery_paused          = optional(bool)
    message_retention_period = optional(number)
    binding                  = optional(string)

    consumer = optional(object({
      type                  = optional(string, "worker")
      script_name           = optional(string)
      dead_letter_queue     = optional(string)
      batch_size            = optional(number)
      max_concurrency       = optional(number)
      max_retries           = optional(number)
      max_wait_time_ms      = optional(number)
      retry_delay           = optional(number)
      visibility_timeout_ms = optional(number)
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for q in values(var.queues) :
      q.consumer == null || contains(["worker", "http_pull"], q.consumer.type)
    ])
    error_message = "Each queue consumer type must be either worker or http_pull."
  }
}

variable "r2_buckets" {
  description = <<-EOT
    R2 buckets to create, keyed by a stable identifier, with their CORS, lifecycle, lock, event notification and
    custom domain configuration. Set `binding` to the variable name the Worker should see.
  EOT
  type = map(object({
    name          = string
    location      = optional(string)
    jurisdiction  = optional(string)
    storage_class = optional(string)
    binding       = optional(string)

    cors_rules = optional(map(object({
      allowed_headers = optional(list(string))
      allowed_methods = list(string)
      allowed_origins = list(string)
      expose_headers  = optional(list(string))
      max_age_seconds = optional(number)
    })), {})

    lifecycle_rules = optional(map(object({
      enabled = optional(bool, true)
      prefix  = optional(string, "")

      abort_multipart_uploads_after_days = optional(number)

      delete_objects_after_days = optional(number)
      delete_objects_on_date    = optional(string)

      storage_class_transitions = optional(map(object({
        storage_class = optional(string, "InfrequentAccess")
        after_days    = optional(number)
        on_date       = optional(string)
      })), {})
    })), {})

    lock_rules = optional(map(object({
      enabled         = optional(bool, true)
      prefix          = optional(string)
      condition_type  = string
      max_age_seconds = optional(number)
      date            = optional(string)
    })), {})

    event_notifications = optional(map(object({
      queue_id = string
      rules = map(object({
        actions     = list(string)
        description = optional(string)
        prefix      = optional(string)
        suffix      = optional(string)
      }))
    })), {})

    custom_domains = optional(map(object({
      domain  = string
      zone_id = string
      enabled = optional(bool, true)
      ciphers = optional(list(string))
      min_tls = optional(string)
    })), {})
  }))
  default = {}
}

variable "hyperdrive_configs" {
  description = <<-EOT
    Hyperdrive configurations to create, keyed by a stable identifier. Set `binding` to the variable name the
    Worker should see.

    `origin.password` is the origin database password, not a Cloudflare credential. It is written to Terraform
    state and the API never returns it, so Terraform cannot detect drift on it.
  EOT
  type = map(object({
    name    = string
    binding = optional(string)

    origin = object({
      database             = string
      scheme               = string
      user                 = string
      password             = string
      host                 = optional(string)
      port                 = optional(number)
      access_client_id     = optional(string)
      access_client_secret = optional(string)
      service_id           = optional(string)
    })

    origin_connection_limit = optional(number)

    caching = optional(object({
      disabled               = optional(bool)
      max_age                = optional(number)
      stale_while_revalidate = optional(number)
    }))

    mtls = optional(object({
      ca_certificate_id   = optional(string)
      mtls_certificate_id = optional(string)
      sslmode             = optional(string)
    }))
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Pages
# -----------------------------------------------------------------------------

variable "pages_projects" {
  description = "Pages projects to create, keyed by a stable identifier. Passed straight through to modules/pages."
  type = map(object({
    name              = string
    production_branch = string

    build_config = optional(object({
      build_command       = optional(string)
      destination_dir     = optional(string)
      root_dir            = optional(string)
      build_caching       = optional(bool)
      web_analytics_tag   = optional(string)
      web_analytics_token = optional(string)
    }))

    source = optional(object({
      type                           = string
      owner                          = optional(string)
      repo_name                      = optional(string)
      production_branch              = optional(string)
      production_deployments_enabled = optional(bool)
      pr_comments_enabled            = optional(bool)
      preview_deployment_setting     = optional(string)
      preview_branch_includes        = optional(list(string))
      preview_branch_excludes        = optional(list(string))
      path_includes                  = optional(list(string))
      path_excludes                  = optional(list(string))
    }))

    preview = optional(object({
      compatibility_date                   = optional(string)
      compatibility_flags                  = optional(list(string))
      always_use_latest_compatibility_date = optional(bool)
      build_image_major_version            = optional(number)
      fail_open                            = optional(bool)
      placement_mode                       = optional(string)
      cpu_ms                               = optional(number)

      env_vars                  = optional(map(object({ type = string, value = string })), {})
      kv_namespaces             = optional(map(string), {})
      d1_databases              = optional(map(string), {})
      hyperdrive_bindings       = optional(map(string), {})
      vectorize_bindings        = optional(map(string), {})
      mtls_certificates         = optional(map(string), {})
      analytics_engine_datasets = optional(map(string), {})
      queue_producers           = optional(map(string), {})
      ai_bindings               = optional(map(string), {})
      durable_object_namespaces = optional(map(string), {})
      browsers                  = optional(set(string), [])
      r2_buckets                = optional(map(object({ name = string, jurisdiction = optional(string) })), {})
      services = optional(map(object({
        service     = string
        environment = optional(string)
        entrypoint  = optional(string)
      })), {})
    }))

    production = optional(object({
      compatibility_date                   = optional(string)
      compatibility_flags                  = optional(list(string))
      always_use_latest_compatibility_date = optional(bool)
      build_image_major_version            = optional(number)
      fail_open                            = optional(bool)
      placement_mode                       = optional(string)
      cpu_ms                               = optional(number)

      env_vars                  = optional(map(object({ type = string, value = string })), {})
      kv_namespaces             = optional(map(string), {})
      d1_databases              = optional(map(string), {})
      hyperdrive_bindings       = optional(map(string), {})
      vectorize_bindings        = optional(map(string), {})
      mtls_certificates         = optional(map(string), {})
      analytics_engine_datasets = optional(map(string), {})
      queue_producers           = optional(map(string), {})
      ai_bindings               = optional(map(string), {})
      durable_object_namespaces = optional(map(string), {})
      browsers                  = optional(set(string), [])
      r2_buckets                = optional(map(object({ name = string, jurisdiction = optional(string) })), {})
      services = optional(map(object({
        service     = string
        environment = optional(string)
        entrypoint  = optional(string)
      })), {})
    }))
  }))
  default = {}
}

variable "pages_domains" {
  description = "Custom domains attached to a Pages project, keyed by a stable identifier."
  type = map(object({
    name         = string
    project_key  = optional(string)
    project_name = optional(string)
  }))
  default = {}
}
