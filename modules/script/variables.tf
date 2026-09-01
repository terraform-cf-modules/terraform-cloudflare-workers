variable "enabled" {
  description = "Whether to create the resources managed by this submodule."
  type        = bool
  default     = true
}

variable "account_id" {
  description = "Cloudflare account ID that owns the Worker."
  type        = string
  default     = null

  validation {
    condition     = var.account_id == null || can(regex("^[0-9a-f]{32}$", var.account_id))
    error_message = "account_id must be a 32 character lowercase hexadecimal Cloudflare account ID."
  }
}

variable "script_name" {
  description = "Name of the Worker. Used in the workers.dev hostname, in route configuration and as the script name in the API."
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

      * `script`    - a single `cloudflare_workers_script`. The stable, generally available surface. Each apply
                      replaces the live code in place.
      * `versioned` - `cloudflare_worker` plus `cloudflare_worker_version` plus `cloudflare_workers_deployment`.
                      Mirrors the versions and deployments API, so a version can be uploaded and then rolled out.
                      Marked beta by the provider.

    See docs/architecture.md for why `script` is the default.
  EOT
  type        = string
  default     = "script"

  validation {
    condition     = contains(["script", "versioned"], var.deployment_model)
    error_message = "deployment_model must be either script or versioned."
  }
}

# -----------------------------------------------------------------------------
# Code
# -----------------------------------------------------------------------------

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
  description = "Content type of the uploaded module, for example application/javascript+module or application/wasm."
  type        = string
  default     = null
}

variable "main_module" {
  description = "Name of the entrypoint module for an ES module Worker, for example worker.js. Mutually exclusive with body_part."
  type        = string
  default     = null
}

variable "body_part" {
  description = "Name of the entrypoint part for a legacy service worker format Worker. Mutually exclusive with main_module."
  type        = string
  default     = null
}

variable "modules" {
  description = <<-EOT
    Extra modules uploaded alongside the entrypoint, keyed by module name. Only used when deployment_model is
    `versioned`; the `script` model uploads a single body.
  EOT
  type = map(object({
    content_type   = string
    content_file   = optional(string)
    content_base64 = optional(string)
    module_name    = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for m in values(var.modules) :
      (m.content_file == null) != (m.content_base64 == null)
    ])
    error_message = "Each module must set exactly one of content_file or content_base64."
  }
}

variable "compatibility_date" {
  description = "Runtime compatibility date, for example 2025-01-01. Pins the Workers runtime behaviour."
  type        = string
  default     = null

  validation {
    condition     = var.compatibility_date == null || can(regex("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", coalesce(var.compatibility_date, "1970-01-01")))
    error_message = "compatibility_date must be an ISO 8601 date in the form YYYY-MM-DD."
  }
}

variable "compatibility_flags" {
  description = "Runtime compatibility flags, for example [\"nodejs_compat\"]."
  type        = set(string)
  default     = null
}

# -----------------------------------------------------------------------------
# Bindings
# -----------------------------------------------------------------------------

variable "bindings" {
  description = <<-EOT
    Worker bindings, keyed by the variable name the Worker sees in its `env` object. The key becomes the binding
    `name`, so it must be a valid JavaScript identifier.

    Each value sets `type` plus the fields that type needs. The common ones:

      | type                 | fields                                                     |
      |----------------------|------------------------------------------------------------|
      | kv_namespace         | namespace_id                                               |
      | d1                   | database_id                                                |
      | r2_bucket            | bucket_name, jurisdiction                                  |
      | queue                | queue_name                                                 |
      | hyperdrive           | id                                                         |
      | service              | service, environment, entrypoint                           |
      | durable_object_namespace | class_name, script_name, environment, namespace_id     |
      | plain_text           | text                                                       |
      | secret_text          | text                                                       |
      | json                 | json                                                       |
      | analytics_engine     | dataset                                                    |
      | vectorize            | index_name                                                 |
      | workflow             | workflow_name, class_name, script_name                     |
      | mtls_certificate     | certificate_id                                             |
      | ratelimit            | namespace_id, simple                                       |
      | ai / browser / assets / version_metadata / images | no extra fields           |

    Values for `secret_text`, `key_base64` and `key_jwk` bindings land in Terraform state. Prefer
    `secrets_store_secret` bindings (store_id, secret_name) for real secrets.
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
    condition = alltrue([
      for b in values(var.bindings) : contains([
        "ai", "ai_search", "ai_search_namespace", "analytics_engine", "assets", "browser", "d1", "data_blob",
        "dispatch_namespace", "durable_object_namespace", "hyperdrive", "inherit", "images", "json",
        "kv_namespace", "media", "mtls_certificate", "plain_text", "pipelines", "queue", "ratelimit",
        "r2_bucket", "secret_text", "send_email", "service", "text_blob", "vectorize", "version_metadata",
        "secrets_store_secret", "secret_key", "workflow", "wasm_module", "vpc_service", "vpc_network"
      ], b.type)
    ])
    error_message = "Each binding type must be one of the values the Cloudflare Workers API accepts. See the Available values list in the provider schema for cloudflare_workers_script.bindings.type."
  }

  validation {
    condition     = alltrue([for k in keys(var.bindings) : can(regex("^[A-Za-z_$][A-Za-z0-9_$]*$", k))])
    error_message = "Each binding key becomes the JavaScript variable name the Worker sees, so it must be a valid JavaScript identifier."
  }

  validation {
    condition     = alltrue([for k, b in var.bindings : b.type != "kv_namespace" || b.namespace_id != null])
    error_message = "Each kv_namespace binding must set namespace_id."
  }

  validation {
    condition     = alltrue([for k, b in var.bindings : b.type != "d1" || b.database_id != null])
    error_message = "Each d1 binding must set database_id."
  }

  validation {
    condition     = alltrue([for k, b in var.bindings : b.type != "r2_bucket" || b.bucket_name != null])
    error_message = "Each r2_bucket binding must set bucket_name."
  }

  validation {
    condition     = alltrue([for k, b in var.bindings : b.type != "queue" || b.queue_name != null])
    error_message = "Each queue binding must set queue_name."
  }

  validation {
    condition     = alltrue([for k, b in var.bindings : b.type != "hyperdrive" || b.id != null])
    error_message = "Each hyperdrive binding must set id."
  }

  validation {
    condition     = alltrue([for k, b in var.bindings : b.type != "service" || b.service != null])
    error_message = "Each service binding must set service."
  }

  validation {
    condition     = alltrue([for k, b in var.bindings : !contains(["plain_text", "secret_text"], b.type) || b.text != null])
    error_message = "Each plain_text or secret_text binding must set text."
  }

  validation {
    condition     = alltrue([for k, b in var.bindings : b.type != "ratelimit" || b.simple != null])
    error_message = "Each ratelimit binding must set simple with limit and period."
  }
}

variable "keep_bindings" {
  description = "Binding types to carry over from the currently deployed Worker rather than replace, for example [\"secret_text\"] to keep secrets set outside Terraform."
  type        = set(string)
  default     = null
}

# -----------------------------------------------------------------------------
# Runtime configuration
# -----------------------------------------------------------------------------

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
  description = "Workers observability settings. `enabled` turns on the whole feature; the nested logs and traces objects tune each stream."
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

  validation {
    condition = (
      var.observability == null ||
      var.observability.head_sampling_rate == null ||
      (var.observability.head_sampling_rate >= 0 && var.observability.head_sampling_rate <= 1)
    )
    error_message = "observability head_sampling_rate must be between 0 and 1."
  }

  validation {
    condition = (
      var.observability == null ||
      var.observability.traces == null ||
      var.observability.traces.propagation_policy == null ||
      contains(["authenticated", "accept"], var.observability.traces.propagation_policy)
    )
    error_message = "observability traces propagation_policy must be either authenticated or accept."
  }
}

variable "tail_consumers" {
  description = "Other Workers that receive this Worker's tail events, keyed by a stable identifier. `service` is the consumer Worker name."
  type = map(object({
    service     = string
    environment = optional(string)
    namespace   = optional(string)
  }))
  default = {}
}

variable "migrations" {
  description = <<-EOT
    Durable Object class migrations applied on upload. `new_sqlite_classes` is the current default storage backend
    for new namespaces; `new_classes` uses the legacy key value backend.
  EOT
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

  validation {
    condition = (
      var.assets == null ||
      var.assets.config == null ||
      var.assets.config.html_handling == null ||
      contains(["auto-trailing-slash", "force-trailing-slash", "drop-trailing-slash", "none"], var.assets.config.html_handling)
    )
    error_message = "assets config html_handling must be one of auto-trailing-slash, force-trailing-slash, drop-trailing-slash, none."
  }

  validation {
    condition = (
      var.assets == null ||
      var.assets.config == null ||
      var.assets.config.not_found_handling == null ||
      contains(["none", "404-page", "single-page-application"], var.assets.config.not_found_handling)
    )
    error_message = "assets config not_found_handling must be one of none, 404-page, single-page-application."
  }
}

variable "workers_dev" {
  description = <<-EOT
    workers.dev subdomain settings. Leave null to leave the subdomain untouched.

      * `enabled`          - serve the Worker on <name>.<subdomain>.workers.dev.
      * `previews_enabled` - serve per version preview URLs.
  EOT
  type = object({
    enabled          = bool
    previews_enabled = optional(bool)
  })
  default = null
}

# -----------------------------------------------------------------------------
# Versioned model only
# -----------------------------------------------------------------------------

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
