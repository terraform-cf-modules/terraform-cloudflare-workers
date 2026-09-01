# Submodule: r2

R2 buckets and everything that hangs off them: CORS, lifecycle, object lock, event notifications and public
custom domains.

All of it is declared inside the bucket entry, because the R2 API addresses a bucket by the triple
`account_id` + `bucket_name` + `jurisdiction` rather than by an ID, and repeating that on every sub resource is
where mistakes happen. This submodule reads the jurisdiction back off the created bucket.

```hcl
module "r2" {
  source  = "terraform-cf-modules/workers/cloudflare//modules/r2"
  version = "~> 0.1"

  account_id = var.account_id

  buckets = {
    uploads = {
      name          = "api-uploads"
      location      = "weur"
      storage_class = "Standard"

      cors_rules = {
        web = {
          allowed_methods = ["GET", "HEAD"]
          allowed_origins = ["https://app.example.com"]
          max_age_seconds = 3600
        }
      }

      lifecycle_rules = {
        expire-temp = {
          prefix                    = "tmp/"
          delete_objects_after_days = 30

          storage_class_transitions = {
            cool = { storage_class = "InfrequentAccess", after_days = 7 }
          }
        }
      }

      lock_rules = {
        retain-audit = { prefix = "audit/", condition_type = "Age", max_age_seconds = 2592000 }
      }

      event_notifications = {
        to-queue = {
          queue_id = var.queue_id
          rules = {
            uploads = { actions = ["PutObject", "CompleteMultipartUpload"], prefix = "incoming/" }
          }
        }
      }

      custom_domains = {
        cdn = { domain = "cdn.example.com", zone_id = var.zone_id, min_tls = "1.2" }
      }
    }
  }
}
```

CORS, lifecycle and lock are one resource per bucket holding a list of rules, so the map keys inside them become
rule IDs. Event notifications and custom domains are one resource per pairing, keyed
`"<bucket key>/<entry key>"` in the outputs.

Bind a bucket to a Worker by name:

```hcl
bindings = {
  UPLOADS = { type = "r2_bucket", bucket_name = module.r2.bucket_names["uploads"] }
}
```

`location` is only honoured the first time a bucket with a given name is created.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10.0 |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | ~> 5.24 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_cloudflare"></a> [cloudflare](#provider\_cloudflare) | ~> 5.24 |

## Resources

| Name | Type |
| ---- | ---- |
| [cloudflare_r2_bucket.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/r2_bucket) | resource |
| [cloudflare_r2_bucket_cors.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/r2_bucket_cors) | resource |
| [cloudflare_r2_bucket_event_notification.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/r2_bucket_event_notification) | resource |
| [cloudflare_r2_bucket_lifecycle.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/r2_bucket_lifecycle) | resource |
| [cloudflare_r2_bucket_lock.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/r2_bucket_lock) | resource |
| [cloudflare_r2_custom_domain.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/r2_custom_domain) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Cloudflare account ID that owns the R2 buckets. | `string` | `null` | no |
| <a name="input_buckets"></a> [buckets](#input\_buckets) | R2 buckets to create, keyed by a stable identifier, together with the configuration attached to each one.<br/><br/>`location` is only honoured the first time a bucket with a given name is created. `jurisdiction` is part of the<br/>bucket identity: every sub resource is addressed with the same jurisdiction, so this module reuses the bucket<br/>value rather than asking for it again.<br/><br/>Sub resources:<br/>  * `cors_rules`                 -> cloudflare\_r2\_bucket\_cors<br/>  * `lifecycle_rules`            -> cloudflare\_r2\_bucket\_lifecycle<br/>  * `lock_rules`                 -> cloudflare\_r2\_bucket\_lock<br/>  * `event_notifications`        -> cloudflare\_r2\_bucket\_event\_notification<br/>  * `custom_domains`             -> cloudflare\_r2\_custom\_domain | <pre>map(object({<br/>    name          = string<br/>    location      = optional(string)<br/>    jurisdiction  = optional(string)<br/>    storage_class = optional(string)<br/><br/>    cors_rules = optional(map(object({<br/>      allowed_headers = optional(list(string))<br/>      allowed_methods = list(string)<br/>      allowed_origins = list(string)<br/>      expose_headers  = optional(list(string))<br/>      max_age_seconds = optional(number)<br/>    })), {})<br/><br/>    lifecycle_rules = optional(map(object({<br/>      enabled = optional(bool, true)<br/>      prefix  = optional(string, "")<br/><br/>      abort_multipart_uploads_after_days = optional(number)<br/><br/>      delete_objects_after_days = optional(number)<br/>      delete_objects_on_date    = optional(string)<br/><br/>      storage_class_transitions = optional(map(object({<br/>        storage_class = optional(string, "InfrequentAccess")<br/>        after_days    = optional(number)<br/>        on_date       = optional(string)<br/>      })), {})<br/>    })), {})<br/><br/>    lock_rules = optional(map(object({<br/>      enabled         = optional(bool, true)<br/>      prefix          = optional(string)<br/>      condition_type  = string<br/>      max_age_seconds = optional(number)<br/>      date            = optional(string)<br/>    })), {})<br/><br/>    event_notifications = optional(map(object({<br/>      queue_id = string<br/>      rules = map(object({<br/>        actions     = list(string)<br/>        description = optional(string)<br/>        prefix      = optional(string)<br/>        suffix      = optional(string)<br/>      }))<br/>    })), {})<br/><br/>    custom_domains = optional(map(object({<br/>      domain  = string<br/>      zone_id = string<br/>      enabled = optional(bool, true)<br/>      ciphers = optional(list(string))<br/>      min_tls = optional(string)<br/>    })), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether to create the resources managed by this submodule. | `bool` | `true` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_bucket_ids"></a> [bucket\_ids](#output\_bucket\_ids) | ID of each created R2 bucket, keyed by the same keys as var.buckets. |
| <a name="output_bucket_names"></a> [bucket\_names](#output\_bucket\_names) | Name of each created R2 bucket, keyed by the same keys as var.buckets. |
| <a name="output_buckets"></a> [buckets](#output\_buckets) | Full cloudflare\_r2\_bucket objects, keyed by the same keys as var.buckets. |
| <a name="output_cors"></a> [cors](#output\_cors) | Full cloudflare\_r2\_bucket\_cors objects, keyed by bucket key. |
| <a name="output_custom_domains"></a> [custom\_domains](#output\_custom\_domains) | Full cloudflare\_r2\_custom\_domain objects, keyed by "<bucket key>/<domain key>". |
| <a name="output_enabled"></a> [enabled](#output\_enabled) | Whether this submodule created its resources. |
| <a name="output_event_notifications"></a> [event\_notifications](#output\_event\_notifications) | Full cloudflare\_r2\_bucket\_event\_notification objects, keyed by "<bucket key>/<notification key>". |
| <a name="output_lifecycle_rules"></a> [lifecycle\_rules](#output\_lifecycle\_rules) | Full cloudflare\_r2\_bucket\_lifecycle objects, keyed by bucket key. |
| <a name="output_locks"></a> [locks](#output\_locks) | Full cloudflare\_r2\_bucket\_lock objects, keyed by bucket key. |
<!-- END_TF_DOCS -->
