# -----------------------------------------------------------------------------
# Submodule: cron
#
# Scheduled invocations of a Worker. The resource owns the complete schedule
# list for a script: whatever it does not contain is removed from Cloudflare.
# -----------------------------------------------------------------------------

locals {
  enabled  = var.enabled
  triggers = local.enabled ? var.triggers : {}
}

resource "cloudflare_workers_cron_trigger" "this" {
  for_each = local.triggers

  account_id  = var.account_id
  script_name = each.value.script_name

  schedules = [for s in each.value.schedules : { cron = s }]
}
