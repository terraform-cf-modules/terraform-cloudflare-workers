# -----------------------------------------------------------------------------
# Submodule: d1
#
# D1 serverless SQL databases.
# -----------------------------------------------------------------------------

locals {
  enabled   = var.enabled
  databases = local.enabled ? var.databases : {}
}

resource "cloudflare_d1_database" "this" {
  for_each = local.databases

  account_id            = var.account_id
  name                  = each.value.name
  primary_location_hint = each.value.primary_location_hint
  jurisdiction          = each.value.jurisdiction

  read_replication = each.value.read_replication_mode == null ? null : {
    mode = each.value.read_replication_mode
  }
}
