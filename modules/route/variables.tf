variable "enabled" {
  description = "Whether to create the resources managed by this submodule."
  type        = bool
  default     = true
}

variable "account_id" {
  description = "Cloudflare account ID that owns the Workers. Required for custom domains."
  type        = string
  default     = null

  validation {
    condition     = var.account_id == null || can(regex("^[0-9a-f]{32}$", var.account_id))
    error_message = "account_id must be a 32 character lowercase hexadecimal Cloudflare account ID."
  }
}

variable "zone_id" {
  description = "Default Cloudflare zone ID for routes and custom domains that do not set their own."
  type        = string
  default     = null

  validation {
    condition     = var.zone_id == null || can(regex("^[0-9a-f]{32}$", var.zone_id))
    error_message = "zone_id must be a 32 character lowercase hexadecimal Cloudflare zone ID."
  }
}

variable "routes" {
  description = <<-EOT
    Worker routes, keyed by a stable identifier.

    A route hangs off a zone and matches request URLs by pattern, for example `example.com/api/*`. Leave `script`
    null to create a route that explicitly bypasses Workers for that pattern.
  EOT
  type = map(object({
    pattern = string
    script  = optional(string)
    zone_id = optional(string)
  }))
  default = {}

  validation {
    condition     = alltrue([for r in values(var.routes) : length(r.pattern) > 0])
    error_message = "Each route pattern must be a non empty string."
  }

  validation {
    condition = alltrue([
      for r in values(var.routes) :
      r.zone_id == null || can(regex("^[0-9a-f]{32}$", r.zone_id))
    ])
    error_message = "Each route zone_id must be a 32 character lowercase hexadecimal Cloudflare zone ID."
  }

  validation {
    condition = alltrue([
      for r in values(var.routes) :
      !startswith(r.pattern, "http://") && !startswith(r.pattern, "https://")
    ])
    error_message = "Route patterns are written without a scheme, for example example.com/api/* rather than https://example.com/api/*."
  }
}

variable "custom_domains" {
  description = <<-EOT
    Worker custom domains, keyed by a stable identifier.

    A custom domain routes every request for a hostname to a Worker and provisions its certificate. Unlike a
    route, it takes the whole hostname rather than a URL pattern.
  EOT
  type = map(object({
    hostname  = string
    service   = string
    zone_id   = optional(string)
    zone_name = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for d in values(var.custom_domains) :
      can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$", d.hostname))
    ])
    error_message = "Each custom domain hostname must be a bare lowercase hostname, for example api.example.com."
  }

  validation {
    condition = alltrue([
      for d in values(var.custom_domains) :
      d.zone_id == null || can(regex("^[0-9a-f]{32}$", d.zone_id))
    ])
    error_message = "Each custom domain zone_id must be a 32 character lowercase hexadecimal Cloudflare zone ID."
  }
}
