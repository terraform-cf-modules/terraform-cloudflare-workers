# Submodule: script

Uploads a Worker. Two shapes, selected by `deployment_model`:

| `deployment_model` | Resources |
|--------------------|-----------|
| `script` (default) | `cloudflare_workers_script`, `cloudflare_workers_script_subdomain` |
| `versioned`        | `cloudflare_worker`, `cloudflare_worker_version`, `cloudflare_workers_deployment` |

`script` is the generally available surface and each apply replaces the live code. `versioned` mirrors the
versions and deployments API, so a version is uploaded and then rolled out, but the provider marks it beta.
`docs/architecture.md` in the repository root explains the trade off in full.

```hcl
module "script" {
  source  = "terraform-cf-modules/workers/cloudflare//modules/script"
  version = "~> 0.1"

  account_id         = var.account_id
  script_name        = "api"
  compatibility_date = "2025-06-01"
  content            = file("${path.module}/worker.js")

  bindings = {
    CACHE       = { type = "kv_namespace", namespace_id = var.namespace_id }
    DB          = { type = "d1", database_id = var.database_id }
    UPLOADS     = { type = "r2_bucket", bucket_name = "api-uploads" }
    JOBS        = { type = "queue", queue_name = "api-jobs" }
    HYPERDRIVE  = { type = "hyperdrive", id = var.hyperdrive_id }
    ENVIRONMENT = { type = "plain_text", text = "production" }
  }

  workers_dev = { enabled = true }
}
```

## Binding fields by type

The map key is the name the Worker sees on `env`. `type` decides which other field the API reads.

| `type` | Fields |
|--------|--------|
| `kv_namespace` | `namespace_id` |
| `d1` | `database_id` |
| `r2_bucket` | `bucket_name`, `jurisdiction` |
| `queue` | `queue_name` |
| `hyperdrive` | `id` |
| `service` | `service`, `environment`, `entrypoint` |
| `durable_object_namespace` | `class_name`, `script_name`, `environment`, `namespace_id` |
| `workflow` | `workflow_name`, `class_name`, `script_name` |
| `plain_text`, `secret_text` | `text` |
| `json` | `json` |
| `analytics_engine` | `dataset` |
| `vectorize` | `index_name` |
| `mtls_certificate` | `certificate_id` |
| `secrets_store_secret` | `store_id`, `secret_name` |
| `ratelimit` | `namespace_id`, `simple` (`limit`, `period`, `mitigation_timeout`) |
| `dispatch_namespace` | `namespace`, `outbound` |
| `send_email` | `destination_address`, `allowed_destination_addresses`, `allowed_sender_addresses` |
| `secret_key` | `algorithm`, `format`, `usages`, `key_base64` or `key_jwk` |
| `ai`, `browser`, `assets`, `images`, `version_metadata` | none |

`secret_text`, `key_base64` and `key_jwk` values are written to Terraform state in plain text. Use
`secrets_store_secret` for real secrets, or set them outside Terraform and pass
`keep_bindings = ["secret_text"]` so an upload does not wipe them.

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
| [cloudflare_worker.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/worker) | resource |
| [cloudflare_worker_version.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/worker_version) | resource |
| [cloudflare_workers_deployment.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/workers_deployment) | resource |
| [cloudflare_workers_script.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/workers_script) | resource |
| [cloudflare_workers_script_subdomain.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/workers_script_subdomain) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Cloudflare account ID that owns the Worker. | `string` | `null` | no |
| <a name="input_assets"></a> [assets](#input\_assets) | Static assets served in front of the Worker. `directory` is a path on the machine running Terraform. | <pre>object({<br/>    directory = optional(string)<br/>    jwt       = optional(string)<br/>    config = optional(object({<br/>      headers            = optional(string)<br/>      redirects          = optional(string)<br/>      html_handling      = optional(string)<br/>      not_found_handling = optional(string)<br/>      run_worker_first   = optional(any)<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_bindings"></a> [bindings](#input\_bindings) | Worker bindings, keyed by the variable name the Worker sees in its `env` object. The key becomes the binding<br/>`name`, so it must be a valid JavaScript identifier.<br/><br/>Each value sets `type` plus the fields that type needs. The common ones:<br/><br/>  \| type                 \| fields                                                     \|<br/>  \|----------------------\|------------------------------------------------------------\|<br/>  \| kv\_namespace         \| namespace\_id                                               \|<br/>  \| d1                   \| database\_id                                                \|<br/>  \| r2\_bucket            \| bucket\_name, jurisdiction                                  \|<br/>  \| queue                \| queue\_name                                                 \|<br/>  \| hyperdrive           \| id                                                         \|<br/>  \| service              \| service, environment, entrypoint                           \|<br/>  \| durable\_object\_namespace \| class\_name, script\_name, environment, namespace\_id     \|<br/>  \| plain\_text           \| text                                                       \|<br/>  \| secret\_text          \| text                                                       \|<br/>  \| json                 \| json                                                       \|<br/>  \| analytics\_engine     \| dataset                                                    \|<br/>  \| vectorize            \| index\_name                                                 \|<br/>  \| workflow             \| workflow\_name, class\_name, script\_name                     \|<br/>  \| mtls\_certificate     \| certificate\_id                                             \|<br/>  \| ratelimit            \| namespace\_id, simple                                       \|<br/>  \| ai / browser / assets / version\_metadata / images \| no extra fields           \|<br/><br/>Values for `secret_text`, `key_base64` and `key_jwk` bindings land in Terraform state. Prefer<br/>`secrets_store_secret` bindings (store\_id, secret\_name) for real secrets. | <pre>map(object({<br/>    type = string<br/><br/>    algorithm                     = optional(string)<br/>    allowed_destination_addresses = optional(list(string))<br/>    allowed_sender_addresses      = optional(list(string))<br/>    app_id                        = optional(string)<br/>    bucket_name                   = optional(string)<br/>    certificate_id                = optional(string)<br/>    class_name                    = optional(string)<br/>    database_id                   = optional(string)<br/>    dataset                       = optional(string)<br/>    destination_address           = optional(string)<br/>    dispatch_namespace            = optional(string)<br/>    entrypoint                    = optional(string)<br/>    environment                   = optional(string)<br/>    format                        = optional(string)<br/>    id                            = optional(string)<br/>    index_name                    = optional(string)<br/>    instance_name                 = optional(string)<br/>    json                          = optional(string)<br/>    jurisdiction                  = optional(string)<br/>    key_base64                    = optional(string)<br/>    key_jwk                       = optional(string)<br/>    namespace                     = optional(string)<br/>    namespace_id                  = optional(string)<br/>    network_id                    = optional(string)<br/>    old_name                      = optional(string)<br/>    part                          = optional(string)<br/>    pipeline                      = optional(string)<br/>    queue_name                    = optional(string)<br/>    script_name                   = optional(string)<br/>    secret_name                   = optional(string)<br/>    service                       = optional(string)<br/>    service_id                    = optional(string)<br/>    store_id                      = optional(string)<br/>    text                          = optional(string)<br/>    tunnel_id                     = optional(string)<br/>    usages                        = optional(set(string))<br/>    version_id                    = optional(string)<br/>    workflow_name                 = optional(string)<br/><br/>    outbound = optional(object({<br/>      params = optional(list(string))<br/>      worker = optional(object({<br/>        environment = optional(string)<br/>        service     = optional(string)<br/>      }))<br/>    }))<br/><br/>    simple = optional(object({<br/>      limit              = number<br/>      period             = number<br/>      mitigation_timeout = optional(number)<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_body_part"></a> [body\_part](#input\_body\_part) | Name of the entrypoint part for a legacy service worker format Worker. Mutually exclusive with main\_module. | `string` | `null` | no |
| <a name="input_compatibility_date"></a> [compatibility\_date](#input\_compatibility\_date) | Runtime compatibility date, for example 2025-01-01. Pins the Workers runtime behaviour. | `string` | `null` | no |
| <a name="input_compatibility_flags"></a> [compatibility\_flags](#input\_compatibility\_flags) | Runtime compatibility flags, for example ["nodejs\_compat"]. | `set(string)` | `null` | no |
| <a name="input_content"></a> [content](#input\_content) | Worker source code, inline. Mutually exclusive with content\_file. | `string` | `null` | no |
| <a name="input_content_file"></a> [content\_file](#input\_content\_file) | Path to a file holding the Worker source code. Mutually exclusive with content. | `string` | `null` | no |
| <a name="input_content_sha256"></a> [content\_sha256](#input\_content\_sha256) | SHA-256 of the Worker source. Set it alongside content\_file so Terraform notices changes to the file. | `string` | `null` | no |
| <a name="input_content_type"></a> [content\_type](#input\_content\_type) | Content type of the uploaded module, for example application/javascript+module or application/wasm. | `string` | `null` | no |
| <a name="input_deployment_message"></a> [deployment\_message](#input\_deployment\_message) | Human readable message recorded against the deployment. Only used when deployment\_model is `versioned`. | `string` | `null` | no |
| <a name="input_deployment_model"></a> [deployment\_model](#input\_deployment\_model) | Which provider resources back the Worker.<br/><br/>  * `script`    - a single `cloudflare_workers_script`. The stable, generally available surface. Each apply<br/>                  replaces the live code in place.<br/>  * `versioned` - `cloudflare_worker` plus `cloudflare_worker_version` plus `cloudflare_workers_deployment`.<br/>                  Mirrors the versions and deployments API, so a version can be uploaded and then rolled out.<br/>                  Marked beta by the provider.<br/><br/>See docs/architecture.md for why `script` is the default. | `string` | `"script"` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether to create the resources managed by this submodule. | `bool` | `true` | no |
| <a name="input_keep_bindings"></a> [keep\_bindings](#input\_keep\_bindings) | Binding types to carry over from the currently deployed Worker rather than replace, for example ["secret\_text"] to keep secrets set outside Terraform. | `set(string)` | `null` | no |
| <a name="input_limits"></a> [limits](#input\_limits) | CPU and subrequest limits for the Worker. | <pre>object({<br/>    cpu_ms      = optional(number)<br/>    subrequests = optional(number)<br/>  })</pre> | `null` | no |
| <a name="input_logpush"></a> [logpush](#input\_logpush) | Whether Workers Logpush is enabled for the Worker. | `bool` | `null` | no |
| <a name="input_main_module"></a> [main\_module](#input\_main\_module) | Name of the entrypoint module for an ES module Worker, for example worker.js. Mutually exclusive with body\_part. | `string` | `null` | no |
| <a name="input_migrations"></a> [migrations](#input\_migrations) | Durable Object class migrations applied on upload. `new_sqlite_classes` is the current default storage backend<br/>for new namespaces; `new_classes` uses the legacy key value backend. | <pre>object({<br/>    old_tag            = optional(string)<br/>    new_tag            = optional(string)<br/>    new_classes        = optional(list(string))<br/>    new_sqlite_classes = optional(list(string))<br/>    deleted_classes    = optional(list(string))<br/>    renamed_classes = optional(map(object({<br/>      from = string<br/>      to   = string<br/>    })), {})<br/>    transferred_classes = optional(map(object({<br/>      from        = string<br/>      from_script = string<br/>      to          = string<br/>    })), {})<br/>  })</pre> | `null` | no |
| <a name="input_modules"></a> [modules](#input\_modules) | Extra modules uploaded alongside the entrypoint, keyed by module name. Only used when deployment\_model is<br/>`versioned`; the `script` model uploads a single body. | <pre>map(object({<br/>    content_type   = string<br/>    content_file   = optional(string)<br/>    content_base64 = optional(string)<br/>    module_name    = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_observability"></a> [observability](#input\_observability) | Workers observability settings. `enabled` turns on the whole feature; the nested logs and traces objects tune each stream. | <pre>object({<br/>    enabled            = bool<br/>    head_sampling_rate = optional(number)<br/>    logs = optional(object({<br/>      enabled            = bool<br/>      invocation_logs    = bool<br/>      destinations       = optional(list(string))<br/>      head_sampling_rate = optional(number)<br/>      persist            = optional(bool)<br/>    }))<br/>    traces = optional(object({<br/>      enabled            = optional(bool)<br/>      destinations       = optional(list(string))<br/>      head_sampling_rate = optional(number)<br/>      persist            = optional(bool)<br/>      propagation_policy = optional(string)<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_placement_mode"></a> [placement\_mode](#input\_placement\_mode) | Smart Placement mode. Leave null to keep the default placement. | `string` | `null` | no |
| <a name="input_script_name"></a> [script\_name](#input\_script\_name) | Name of the Worker. Used in the workers.dev hostname, in route configuration and as the script name in the API. | `string` | `null` | no |
| <a name="input_tail_consumers"></a> [tail\_consumers](#input\_tail\_consumers) | Other Workers that receive this Worker's tail events, keyed by a stable identifier. `service` is the consumer Worker name. | <pre>map(object({<br/>    service     = string<br/>    environment = optional(string)<br/>    namespace   = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_usage_model"></a> [usage\_model](#input\_usage\_model) | Billing usage model for the Worker. | `string` | `null` | no |
| <a name="input_version_message"></a> [version\_message](#input\_version\_message) | Human readable message recorded against the uploaded version. Only used when deployment\_model is `versioned`. | `string` | `null` | no |
| <a name="input_version_tag"></a> [version\_tag](#input\_version\_tag) | Caller supplied identifier recorded against the uploaded version. Only used when deployment\_model is `versioned`. | `string` | `null` | no |
| <a name="input_worker_tags"></a> [worker\_tags](#input\_worker\_tags) | Tags attached to the Worker. Only used when deployment\_model is `versioned`. | `set(string)` | `null` | no |
| <a name="input_workers_dev"></a> [workers\_dev](#input\_workers\_dev) | workers.dev subdomain settings. Leave null to leave the subdomain untouched.<br/><br/>  * `enabled`          - serve the Worker on <name>.<subdomain>.workers.dev.<br/>  * `previews_enabled` - serve per version preview URLs. | <pre>object({<br/>    enabled          = bool<br/>    previews_enabled = optional(bool)<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_deployment"></a> [deployment](#output\_deployment) | Full cloudflare\_workers\_deployment object, or null in the script model. |
| <a name="output_deployment_model"></a> [deployment\_model](#output\_deployment\_model) | Which provider resources back the Worker: script or versioned. |
| <a name="output_enabled"></a> [enabled](#output\_enabled) | Whether this submodule created its resources. |
| <a name="output_etag"></a> [etag](#output\_etag) | Etag of the uploaded script, or null in the versioned model. |
| <a name="output_id"></a> [id](#output\_id) | ID of the Worker. The script name in the script model, the immutable Worker ID in the versioned model. |
| <a name="output_script"></a> [script](#output\_script) | Full cloudflare\_workers\_script object, or null in the versioned model. Contains binding values. |
| <a name="output_script_name"></a> [script\_name](#output\_script\_name) | Name of the Worker, read back from the resource so dependent resources order correctly. |
| <a name="output_subdomain"></a> [subdomain](#output\_subdomain) | Full cloudflare\_workers\_script\_subdomain object, or null when workers\_dev was not set. |
| <a name="output_worker"></a> [worker](#output\_worker) | Full cloudflare\_worker object, or null in the script model. |
| <a name="output_worker_version"></a> [worker\_version](#output\_worker\_version) | Full cloudflare\_worker\_version object, or null in the script model. Contains binding values. |
| <a name="output_workers_dev_url"></a> [workers\_dev\_url](#output\_workers\_dev\_url) | The workers.dev address the Worker serves on, when the versioned model reports one. |
<!-- END_TF_DOCS -->
