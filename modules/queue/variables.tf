variable "enabled" {
  description = "Whether to create the resources managed by this submodule."
  type        = bool
  default     = true
}

variable "account_id" {
  description = "Cloudflare account ID that owns the queues."
  type        = string
  default     = null

  validation {
    condition     = var.account_id == null || can(regex("^[0-9a-f]{32}$", var.account_id))
    error_message = "account_id must be a 32 character lowercase hexadecimal Cloudflare account ID."
  }
}

variable "queues" {
  description = <<-EOT
    Cloudflare Queues to create, keyed by a stable identifier.

    `delivery_delay` and `message_retention_period` are in seconds. `delivery_paused` stops delivery to consumers
    without deleting the queue.
  EOT
  type = map(object({
    queue_name               = string
    delivery_delay           = optional(number)
    delivery_paused          = optional(bool)
    message_retention_period = optional(number)
  }))
  default = {}

  validation {
    condition = alltrue([
      for q in values(var.queues) :
      can(regex("^[a-zA-Z0-9][a-zA-Z0-9-_]{0,62}$", q.queue_name))
    ])
    error_message = "Each queue_name must start with an alphanumeric character and contain only alphanumerics, dashes and underscores, up to 63 characters."
  }

  validation {
    condition = alltrue([
      for q in values(var.queues) :
      q.message_retention_period == null || (q.message_retention_period >= 60 && q.message_retention_period <= 1209600)
    ])
    error_message = "Each queue message_retention_period must be between 60 and 1209600 seconds (14 days)."
  }

  validation {
    condition = alltrue([
      for q in values(var.queues) :
      q.delivery_delay == null || (q.delivery_delay >= 0 && q.delivery_delay <= 43200)
    ])
    error_message = "Each queue delivery_delay must be between 0 and 43200 seconds (12 hours)."
  }
}

variable "consumers" {
  description = <<-EOT
    Queue consumers, keyed by a stable identifier.

    Set `queue_key` to consume a queue created by this submodule, or `queue_id` to consume an existing queue.
    Exactly one of the two must be set. `type` is `worker` for push consumers and `http_pull` for pull consumers;
    `script_name` only applies to `worker` consumers.
  EOT
  type = map(object({
    type                  = string
    queue_key             = optional(string)
    queue_id              = optional(string)
    script_name           = optional(string)
    dead_letter_queue     = optional(string)
    batch_size            = optional(number)
    max_concurrency       = optional(number)
    max_retries           = optional(number)
    max_wait_time_ms      = optional(number)
    retry_delay           = optional(number)
    visibility_timeout_ms = optional(number)
  }))
  default = {}

  validation {
    condition     = alltrue([for c in values(var.consumers) : contains(["worker", "http_pull"], c.type)])
    error_message = "Each consumer type must be either worker or http_pull."
  }

  validation {
    condition = alltrue([
      for c in values(var.consumers) :
      (c.queue_key == null) != (c.queue_id == null)
    ])
    error_message = "Each consumer must set exactly one of queue_key or queue_id."
  }

  validation {
    condition = alltrue([
      for c in values(var.consumers) :
      c.queue_key == null || contains(keys(var.queues), c.queue_key)
    ])
    error_message = "Each consumer queue_key must match a key in var.queues."
  }

  validation {
    condition = alltrue([
      for c in values(var.consumers) :
      c.type != "worker" || c.script_name != null
    ])
    error_message = "Each consumer of type worker must set script_name."
  }
}
