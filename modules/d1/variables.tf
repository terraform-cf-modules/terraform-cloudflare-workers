variable "enabled" {
  description = "Whether to create the resources managed by this submodule."
  type        = bool
  default     = true
}

variable "account_id" {
  description = "Cloudflare account ID that owns the D1 databases."
  type        = string
  default     = null

  validation {
    condition     = var.account_id == null || can(regex("^[0-9a-f]{32}$", var.account_id))
    error_message = "account_id must be a 32 character lowercase hexadecimal Cloudflare account ID."
  }
}

variable "databases" {
  description = <<-EOT
    D1 databases to create, keyed by a stable identifier.

    `primary_location_hint` places the primary replica. `jurisdiction` pins storage to a data boundary and, when
    set, Cloudflare ignores the location hint. `read_replication_mode` turns global read replicas on or off.
  EOT
  type = map(object({
    name                  = string
    primary_location_hint = optional(string)
    jurisdiction          = optional(string)
    read_replication_mode = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for d in values(var.databases) :
      d.primary_location_hint == null || contains(["wnam", "enam", "weur", "eeur", "apac", "oc"], d.primary_location_hint)
    ])
    error_message = "Each database primary_location_hint must be one of wnam, enam, weur, eeur, apac, oc."
  }

  validation {
    condition = alltrue([
      for d in values(var.databases) :
      d.jurisdiction == null || contains(["eu", "fedramp", "us"], d.jurisdiction)
    ])
    error_message = "Each database jurisdiction must be one of eu, fedramp, us."
  }

  validation {
    condition = alltrue([
      for d in values(var.databases) :
      d.read_replication_mode == null || contains(["auto", "disabled"], d.read_replication_mode)
    ])
    error_message = "Each database read_replication_mode must be either auto or disabled."
  }
}
