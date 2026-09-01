variable "enabled" {
  description = "Whether to create the resources managed by this submodule."
  type        = bool
  default     = true
}

variable "account_id" {
  description = "Cloudflare account ID that owns the Hyperdrive configurations."
  type        = string
  default     = null

  validation {
    condition     = var.account_id == null || can(regex("^[0-9a-f]{32}$", var.account_id))
    error_message = "account_id must be a 32 character lowercase hexadecimal Cloudflare account ID."
  }
}

variable "configs" {
  description = <<-EOT
    Hyperdrive configurations to create, keyed by a stable identifier.

    `origin.password` is the password of the origin database, not a Cloudflare credential. The Cloudflare API never
    returns it, so Terraform cannot detect drift on it. Source it from a secret manager rather than a literal, and
    keep in mind that whatever you pass ends up in Terraform state.

    Reach the origin either directly (`host` and `port`), through Cloudflare Access (`access_client_id` and
    `access_client_secret`), or through a Workers VPC service (`service_id`).
  EOT
  type = map(object({
    name = string

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
  # Deliberately not marked sensitive: Terraform refuses a sensitive value as a for_each argument, and the
  # provider schema already marks origin.password and origin.access_client_secret sensitive, so plan output
  # redacts them on the resource itself.
  default = {}

  validation {
    condition = alltrue([
      for c in values(var.configs) :
      contains(["postgres", "postgresql", "mysql"], c.origin.scheme)
    ])
    error_message = "Each origin scheme must be one of postgres, postgresql, mysql."
  }

  validation {
    condition = alltrue([
      for c in values(var.configs) :
      c.mtls == null || c.mtls.sslmode == null || contains(["require", "verify-ca", "verify-full"], c.mtls.sslmode)
    ])
    error_message = "Each mtls sslmode must be one of require, verify-ca, verify-full."
  }

  validation {
    condition = alltrue([
      for c in values(var.configs) :
      c.origin_connection_limit == null || (c.origin_connection_limit >= 1 && c.origin_connection_limit <= 100)
    ])
    error_message = "Each origin_connection_limit must be between 1 and 100."
  }

  validation {
    condition = alltrue([
      for c in values(var.configs) :
      c.origin.host != null || c.origin.service_id != null
    ])
    error_message = "Each origin must set either host or service_id."
  }
}
