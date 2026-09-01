# -----------------------------------------------------------------------------
# Submodule: hyperdrive
#
# Hyperdrive connection pools in front of an existing PostgreSQL or MySQL
# origin. A Worker reaches one through a `hyperdrive` binding carrying the
# config ID.
# -----------------------------------------------------------------------------

locals {
  enabled = var.enabled
  configs = local.enabled ? var.configs : {}
}

resource "cloudflare_hyperdrive_config" "this" {
  for_each = local.configs

  account_id              = var.account_id
  name                    = each.value.name
  origin_connection_limit = each.value.origin_connection_limit

  origin = {
    database             = each.value.origin.database
    scheme               = each.value.origin.scheme
    user                 = each.value.origin.user
    password             = each.value.origin.password
    host                 = each.value.origin.host
    port                 = each.value.origin.port
    access_client_id     = each.value.origin.access_client_id
    access_client_secret = each.value.origin.access_client_secret
    service_id           = each.value.origin.service_id
  }

  caching = each.value.caching == null ? null : {
    disabled               = each.value.caching.disabled
    max_age                = each.value.caching.max_age
    stale_while_revalidate = each.value.caching.stale_while_revalidate
  }

  mtls = each.value.mtls == null ? null : {
    ca_certificate_id   = each.value.mtls.ca_certificate_id
    mtls_certificate_id = each.value.mtls.mtls_certificate_id
    sslmode             = each.value.mtls.sslmode
  }
}
