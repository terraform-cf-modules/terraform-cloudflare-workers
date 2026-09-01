# -----------------------------------------------------------------------------
# Submodule: kv
#
# Workers KV namespaces and the key/value pairs stored inside them.
# -----------------------------------------------------------------------------

locals {
  enabled = var.enabled

  namespaces = local.enabled ? var.namespaces : {}
  pairs      = local.enabled ? var.pairs : {}
}

resource "cloudflare_workers_kv_namespace" "this" {
  for_each = local.namespaces

  account_id = var.account_id
  title      = each.value.title
}

resource "cloudflare_workers_kv" "this" {
  for_each = local.pairs

  account_id = var.account_id
  key_name   = each.value.key_name
  value      = each.value.value
  metadata   = each.value.metadata

  namespace_id = (
    each.value.namespace_key != null
    ? cloudflare_workers_kv_namespace.this[each.value.namespace_key].id
    : each.value.namespace_id
  )
}
