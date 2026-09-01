variable "enabled" {
  description = "Whether to create the resources managed by this submodule."
  type        = bool
  default     = true
}

variable "account_id" {
  description = "Cloudflare account ID that owns the Workers."
  type        = string
  default     = null

  validation {
    condition     = var.account_id == null || can(regex("^[0-9a-f]{32}$", var.account_id))
    error_message = "account_id must be a 32 character lowercase hexadecimal Cloudflare account ID."
  }
}

variable "triggers" {
  description = <<-EOT
    Cron triggers, keyed by a stable identifier.

    One resource holds every schedule for a script, so a second entry for the same `script_name` overwrites the
    first. Put all of a Worker's schedules in one entry.

    Cloudflare accepts standard five field cron expressions in UTC, plus the `@hourly`, `@daily`, `@weekly`,
    `@monthly` and `@yearly` shorthands.
  EOT
  type = map(object({
    script_name = string
    schedules   = list(string)
  }))
  default = {}

  validation {
    condition     = alltrue([for t in values(var.triggers) : length(t.schedules) > 0])
    error_message = "Each cron trigger must list at least one schedule."
  }

  validation {
    condition = alltrue(flatten([
      for t in values(var.triggers) : [
        for s in t.schedules :
        contains(["@hourly", "@daily", "@weekly", "@monthly", "@yearly"], s) ||
        can(regex("^\\S+( +\\S+){4}$", s))
      ]
    ]))
    error_message = "Each schedule must be a five field cron expression or one of @hourly, @daily, @weekly, @monthly, @yearly."
  }

  validation {
    condition     = length(distinct([for t in values(var.triggers) : t.script_name])) == length(var.triggers)
    error_message = "Each script_name may appear in only one trigger entry, because one resource owns every schedule for a script."
  }
}
