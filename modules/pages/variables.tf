variable "enabled" {
  description = "Whether to create the resources managed by this submodule."
  type        = bool
  default     = true
}

variable "account_id" {
  description = "Cloudflare account ID that owns the Pages projects."
  type        = string
  default     = null

  validation {
    condition     = var.account_id == null || can(regex("^[0-9a-f]{32}$", var.account_id))
    error_message = "account_id must be a 32 character lowercase hexadecimal Cloudflare account ID."
  }
}

variable "projects" {
  description = <<-EOT
    Pages projects to create, keyed by a stable identifier.

    `source` connects the project to a git provider so pushes trigger builds. Leave it null for a project you
    deploy with Wrangler or the API.

    `preview` and `production` carry the per environment Functions configuration: bindings, environment variables,
    compatibility settings and limits. Both take the same shape.

    Environment variables of type `secret_text` are stored in Terraform state in plain text.
  EOT
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

  validation {
    condition = alltrue([
      for p in values(var.projects) :
      can(regex("^[a-z0-9][a-z0-9-]{0,57}[a-z0-9]$", p.name))
    ])
    error_message = "Each Pages project name must be lowercase alphanumeric with dashes, 2 to 59 characters, and must not start or end with a dash."
  }

  validation {
    condition = alltrue([
      for p in values(var.projects) :
      p.source == null || contains(["github", "gitlab"], p.source.type)
    ])
    error_message = "Each project source type must be either github or gitlab."
  }

  validation {
    condition = alltrue([
      for p in values(var.projects) :
      p.source == null || p.source.preview_deployment_setting == null ||
      contains(["all", "none", "custom"], p.source.preview_deployment_setting)
    ])
    error_message = "Each project source preview_deployment_setting must be one of all, none, custom."
  }

  validation {
    condition = alltrue(flatten([
      for p in values(var.projects) : [
        for e in [p.preview, p.production] :
        e == null ? true : alltrue([
          for v in values(e.env_vars) : contains(["plain_text", "secret_text"], v.type)
        ])
      ]
    ]))
    error_message = "Each Pages environment variable type must be either plain_text or secret_text."
  }

  validation {
    condition = alltrue(flatten([
      for p in values(var.projects) : [
        for e in [p.preview, p.production] :
        e == null || e.placement_mode == null ? true : contains(["smart"], coalesce(e.placement_mode, "smart"))
      ]
    ]))
    error_message = "Each deployment config placement_mode must be smart."
  }
}

variable "domains" {
  description = <<-EOT
    Custom domains attached to a Pages project, keyed by a stable identifier.

    Set `project_key` to attach to a project created by this submodule, or `project_name` to attach to an existing
    one. Exactly one of the two must be set.
  EOT
  type = map(object({
    name         = string
    project_key  = optional(string)
    project_name = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for d in values(var.domains) :
      (d.project_key == null) != (d.project_name == null)
    ])
    error_message = "Each Pages domain must set exactly one of project_key or project_name."
  }

  validation {
    condition = alltrue([
      for d in values(var.domains) :
      d.project_key == null || contains(keys(var.projects), d.project_key)
    ])
    error_message = "Each Pages domain project_key must match a key in var.projects."
  }
}
