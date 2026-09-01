variable "enabled" {
  description = "Whether to create the resources managed by this submodule."
  type        = bool
  default     = true
}

variable "account_id" {
  description = "Cloudflare account ID that owns the KV namespaces."
  type        = string
  default     = null

  validation {
    condition     = var.account_id == null || can(regex("^[0-9a-f]{32}$", var.account_id))
    error_message = "account_id must be a 32 character lowercase hexadecimal Cloudflare account ID."
  }
}

variable "namespaces" {
  description = <<-EOT
    Workers KV namespaces to create, keyed by a stable identifier. The key is only a state address; `title` is the
    human readable name Cloudflare stores.
  EOT
  type = map(object({
    title = string
  }))
  default = {}

  validation {
    condition     = alltrue([for n in values(var.namespaces) : length(n.title) > 0 && length(n.title) <= 512])
    error_message = "Each KV namespace title must be between 1 and 512 characters."
  }
}

variable "pairs" {
  description = <<-EOT
    Key/value pairs to write into a namespace, keyed by a stable identifier.

    Set `namespace_key` to reference a namespace created by this submodule, or `namespace_id` to write into a
    namespace that already exists. Exactly one of the two must be set.

    `value` is stored in Terraform state in plain text. Do not put secrets here; use a `secret_text` Worker
    binding or Cloudflare Secrets Store instead.
  EOT
  type = map(object({
    key_name      = string
    value         = string
    namespace_key = optional(string)
    namespace_id  = optional(string)
    metadata      = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for p in values(var.pairs) :
      (p.namespace_key == null) != (p.namespace_id == null)
    ])
    error_message = "Each KV pair must set exactly one of namespace_key or namespace_id."
  }

  validation {
    condition = alltrue([
      for p in values(var.pairs) :
      p.namespace_key == null || contains(keys(var.namespaces), p.namespace_key)
    ])
    error_message = "Each KV pair namespace_key must match a key in var.namespaces."
  }

  validation {
    condition = alltrue([
      for p in values(var.pairs) :
      p.namespace_id == null || can(regex("^[0-9a-f]{32}$", p.namespace_id))
    ])
    error_message = "Each KV pair namespace_id must be a 32 character lowercase hexadecimal namespace ID."
  }
}
