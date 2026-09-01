# -----------------------------------------------------------------------------
# Submodule: r2
#
# R2 buckets plus the configuration objects that hang off them. CORS, lifecycle
# and lock are one resource per bucket holding a list of rules; event
# notifications and custom domains are one resource per pairing.
#
# Every sub resource repeats account_id, bucket_name and jurisdiction because
# the R2 API addresses a bucket by that triple, not by an opaque ID.
# -----------------------------------------------------------------------------

locals {
  enabled = var.enabled
  buckets = local.enabled ? var.buckets : {}

  cors_buckets      = { for k, b in local.buckets : k => b if length(b.cors_rules) > 0 }
  lifecycle_buckets = { for k, b in local.buckets : k => b if length(b.lifecycle_rules) > 0 }
  lock_buckets      = { for k, b in local.buckets : k => b if length(b.lock_rules) > 0 }

  event_notifications = merge([
    for bk, b in local.buckets : {
      for nk, n in b.event_notifications : "${bk}/${nk}" => {
        bucket_key = bk
        queue_id   = n.queue_id
        rules      = n.rules
      }
    }
  ]...)

  custom_domains = merge([
    for bk, b in local.buckets : {
      for dk, d in b.custom_domains : "${bk}/${dk}" => {
        bucket_key = bk
        domain     = d.domain
        zone_id    = d.zone_id
        enabled    = d.enabled
        ciphers    = d.ciphers
        min_tls    = d.min_tls
      }
    }
  ]...)
}

resource "cloudflare_r2_bucket" "this" {
  for_each = local.buckets

  account_id    = var.account_id
  name          = each.value.name
  location      = each.value.location
  jurisdiction  = each.value.jurisdiction
  storage_class = each.value.storage_class
}

resource "cloudflare_r2_bucket_cors" "this" {
  for_each = local.cors_buckets

  account_id   = var.account_id
  bucket_name  = cloudflare_r2_bucket.this[each.key].name
  jurisdiction = cloudflare_r2_bucket.this[each.key].jurisdiction

  rules = [
    for id, r in each.value.cors_rules : {
      id = id
      allowed = {
        headers = r.allowed_headers
        methods = r.allowed_methods
        origins = r.allowed_origins
      }
      expose_headers  = r.expose_headers
      max_age_seconds = r.max_age_seconds
    }
  ]
}

resource "cloudflare_r2_bucket_lifecycle" "this" {
  for_each = local.lifecycle_buckets

  account_id   = var.account_id
  bucket_name  = cloudflare_r2_bucket.this[each.key].name
  jurisdiction = cloudflare_r2_bucket.this[each.key].jurisdiction

  rules = [
    for id, r in each.value.lifecycle_rules : {
      id      = id
      enabled = r.enabled

      conditions = {
        prefix = r.prefix
      }

      abort_multipart_uploads_transition = r.abort_multipart_uploads_after_days == null ? null : {
        condition = {
          type    = "Age"
          max_age = r.abort_multipart_uploads_after_days
        }
      }

      delete_objects_transition = (
        r.delete_objects_after_days == null && r.delete_objects_on_date == null ? null : {
          condition = {
            type    = r.delete_objects_after_days != null ? "Age" : "Date"
            max_age = r.delete_objects_after_days
            date    = r.delete_objects_on_date
          }
        }
      )

      storage_class_transitions = [
        for t in values(r.storage_class_transitions) : {
          storage_class = t.storage_class
          condition = {
            type    = t.after_days != null ? "Age" : "Date"
            max_age = t.after_days
            date    = t.on_date
          }
        }
      ]
    }
  ]
}

resource "cloudflare_r2_bucket_lock" "this" {
  for_each = local.lock_buckets

  account_id   = var.account_id
  bucket_name  = cloudflare_r2_bucket.this[each.key].name
  jurisdiction = cloudflare_r2_bucket.this[each.key].jurisdiction

  rules = [
    for id, r in each.value.lock_rules : {
      id      = id
      enabled = r.enabled
      prefix  = r.prefix
      condition = {
        type            = r.condition_type
        max_age_seconds = r.max_age_seconds
        date            = r.date
      }
    }
  ]
}

resource "cloudflare_r2_bucket_event_notification" "this" {
  for_each = local.event_notifications

  account_id   = var.account_id
  bucket_name  = cloudflare_r2_bucket.this[each.value.bucket_key].name
  jurisdiction = cloudflare_r2_bucket.this[each.value.bucket_key].jurisdiction
  queue_id     = each.value.queue_id

  rules = [
    for k, r in each.value.rules : {
      actions     = r.actions
      description = coalesce(r.description, k)
      prefix      = r.prefix
      suffix      = r.suffix
    }
  ]
}

resource "cloudflare_r2_custom_domain" "this" {
  for_each = local.custom_domains

  account_id   = var.account_id
  bucket_name  = cloudflare_r2_bucket.this[each.value.bucket_key].name
  jurisdiction = cloudflare_r2_bucket.this[each.value.bucket_key].jurisdiction
  domain       = each.value.domain
  zone_id      = each.value.zone_id
  enabled      = each.value.enabled
  ciphers      = each.value.ciphers
  min_tls      = each.value.min_tls
}
