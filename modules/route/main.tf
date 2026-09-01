# -----------------------------------------------------------------------------
# Submodule: route
#
# The two ways traffic reaches a Worker from a zone you own:
#
#   cloudflare_workers_route         URL pattern on an existing zone record
#   cloudflare_workers_custom_domain whole hostname, certificate provisioned by Cloudflare
# -----------------------------------------------------------------------------

locals {
  enabled = var.enabled

  routes         = local.enabled ? var.routes : {}
  custom_domains = local.enabled ? var.custom_domains : {}
}

resource "cloudflare_workers_route" "this" {
  for_each = local.routes

  zone_id = coalesce(each.value.zone_id, var.zone_id)
  pattern = each.value.pattern
  script  = each.value.script
}

resource "cloudflare_workers_custom_domain" "this" {
  for_each = local.custom_domains

  account_id = var.account_id
  hostname   = each.value.hostname
  service    = each.value.service
  zone_id    = each.value.zone_name != null ? null : coalesce(each.value.zone_id, var.zone_id)
  zone_name  = each.value.zone_name
}
