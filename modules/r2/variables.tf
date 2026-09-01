variable "enabled" {
  description = "Whether to create the resources managed by this submodule."
  type        = bool
  default     = true
}

variable "account_id" {
  description = "Cloudflare account ID that owns the R2 buckets."
  type        = string
  default     = null

  validation {
    condition     = var.account_id == null || can(regex("^[0-9a-f]{32}$", var.account_id))
    error_message = "account_id must be a 32 character lowercase hexadecimal Cloudflare account ID."
  }
}

variable "buckets" {
  description = <<-EOT
    R2 buckets to create, keyed by a stable identifier, together with the configuration attached to each one.

    `location` is only honoured the first time a bucket with a given name is created. `jurisdiction` is part of the
    bucket identity: every sub resource is addressed with the same jurisdiction, so this module reuses the bucket
    value rather than asking for it again.

    Sub resources:
      * `cors_rules`                 -> cloudflare_r2_bucket_cors
      * `lifecycle_rules`            -> cloudflare_r2_bucket_lifecycle
      * `lock_rules`                 -> cloudflare_r2_bucket_lock
      * `event_notifications`        -> cloudflare_r2_bucket_event_notification
      * `custom_domains`             -> cloudflare_r2_custom_domain
  EOT
  type = map(object({
    name          = string
    location      = optional(string)
    jurisdiction  = optional(string)
    storage_class = optional(string)

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

  validation {
    condition = alltrue([
      for b in values(var.buckets) :
      b.location == null || contains(["apac", "eeur", "enam", "weur", "wnam", "oc"], b.location)
    ])
    error_message = "Each bucket location must be one of apac, eeur, enam, weur, wnam, oc."
  }

  validation {
    condition = alltrue([
      for b in values(var.buckets) :
      b.jurisdiction == null || contains(["default", "eu", "fedramp", "us"], b.jurisdiction)
    ])
    error_message = "Each bucket jurisdiction must be one of default, eu, fedramp, us."
  }

  validation {
    condition = alltrue([
      for b in values(var.buckets) :
      b.storage_class == null || contains(["Standard", "InfrequentAccess"], b.storage_class)
    ])
    error_message = "Each bucket storage_class must be either Standard or InfrequentAccess."
  }

  validation {
    condition = alltrue(flatten([
      for b in values(var.buckets) : [
        for r in values(b.cors_rules) : [
          for m in r.allowed_methods : contains(["GET", "PUT", "POST", "DELETE", "HEAD"], m)
        ]
      ]
    ]))
    error_message = "Each CORS allowed_methods entry must be one of GET, PUT, POST, DELETE, HEAD."
  }

  validation {
    condition = alltrue(flatten([
      for b in values(var.buckets) : [
        for r in values(b.lock_rules) : contains(["Age", "Date", "Indefinite"], r.condition_type)
      ]
    ]))
    error_message = "Each lock rule condition_type must be one of Age, Date, Indefinite."
  }

  validation {
    condition = alltrue(flatten([
      for b in values(var.buckets) : [
        for r in values(b.lock_rules) :
        r.condition_type != "Age" || r.max_age_seconds != null
      ]
    ]))
    error_message = "A lock rule with condition_type Age must set max_age_seconds."
  }

  validation {
    condition = alltrue(flatten([
      for b in values(var.buckets) : [
        for r in values(b.lock_rules) :
        r.condition_type != "Date" || r.date != null
      ]
    ]))
    error_message = "A lock rule with condition_type Date must set date."
  }

  validation {
    condition = alltrue(flatten([
      for b in values(var.buckets) : [
        for r in values(b.lifecycle_rules) :
        (r.delete_objects_after_days == null) || (r.delete_objects_on_date == null)
      ]
    ]))
    error_message = "A lifecycle rule cannot set both delete_objects_after_days and delete_objects_on_date."
  }

  validation {
    condition = alltrue(flatten([
      for b in values(var.buckets) : [
        for r in values(b.lifecycle_rules) : [
          for t in values(r.storage_class_transitions) :
          (t.after_days == null) != (t.on_date == null)
        ]
      ]
    ]))
    error_message = "Each storage class transition must set exactly one of after_days or on_date."
  }

  validation {
    condition = alltrue(flatten([
      for b in values(var.buckets) : [
        for n in values(b.event_notifications) : [
          for r in values(n.rules) : [
            for a in r.actions : contains([
              "PutObject", "CopyObject", "DeleteObject", "CompleteMultipartUpload", "LifecycleDeletion"
            ], a)
          ]
        ]
      ]
    ]))
    error_message = "Each event notification action must be one of PutObject, CopyObject, DeleteObject, CompleteMultipartUpload, LifecycleDeletion."
  }

  validation {
    condition = alltrue(flatten([
      for b in values(var.buckets) : [
        for d in values(b.custom_domains) :
        d.min_tls == null || contains(["1.0", "1.1", "1.2", "1.3"], d.min_tls)
      ]
    ]))
    error_message = "Each custom domain min_tls must be one of 1.0, 1.1, 1.2, 1.3."
  }
}
