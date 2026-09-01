# Submodule: kv

Workers KV namespaces and the key/value pairs stored inside them.

```hcl
module "kv" {
  source  = "terraform-cf-modules/workers/cloudflare//modules/kv"
  version = "~> 0.1"

  account_id = var.account_id

  namespaces = {
    cache = { title = "api-cache" }
  }

  pairs = {
    greeting = {
      namespace_key = "cache"     # a key in var.namespaces
      key_name      = "greeting"
      value         = "hello"
      metadata      = jsonencode({ owner = "platform" })
    }
  }
}
```

Bind a namespace to a Worker with its `id`:

```hcl
bindings = {
  CACHE = { type = "kv_namespace", namespace_id = module.kv.namespace_ids["cache"] }
}
```

Values written through `pairs` are stored in Terraform state in plain text. Keep secrets out of them.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.12.0 |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | ~> 5.24 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_cloudflare"></a> [cloudflare](#provider\_cloudflare) | ~> 5.24 |

## Resources

| Name | Type |
| ---- | ---- |
| [cloudflare_workers_kv.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/workers_kv) | resource |
| [cloudflare_workers_kv_namespace.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/workers_kv_namespace) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Cloudflare account ID that owns the KV namespaces. | `string` | `null` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether to create the resources managed by this submodule. | `bool` | `true` | no |
| <a name="input_namespaces"></a> [namespaces](#input\_namespaces) | Workers KV namespaces to create, keyed by a stable identifier. The key is only a state address; `title` is the<br/>human readable name Cloudflare stores. | <pre>map(object({<br/>    title = string<br/>  }))</pre> | `{}` | no |
| <a name="input_pairs"></a> [pairs](#input\_pairs) | Key/value pairs to write into a namespace, keyed by a stable identifier.<br/><br/>Set `namespace_key` to reference a namespace created by this submodule, or `namespace_id` to write into a<br/>namespace that already exists. Exactly one of the two must be set.<br/><br/>`value` is stored in Terraform state in plain text. Do not put secrets here; use a `secret_text` Worker<br/>binding or Cloudflare Secrets Store instead. | <pre>map(object({<br/>    key_name      = string<br/>    value         = string<br/>    namespace_key = optional(string)<br/>    namespace_id  = optional(string)<br/>    metadata      = optional(string)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_enabled"></a> [enabled](#output\_enabled) | Whether this submodule created its resources. |
| <a name="output_namespace_ids"></a> [namespace\_ids](#output\_namespace\_ids) | Namespace ID of each created KV namespace, keyed by the same keys as var.namespaces. |
| <a name="output_namespaces"></a> [namespaces](#output\_namespaces) | Full cloudflare\_workers\_kv\_namespace objects, keyed by the same keys as var.namespaces. |
| <a name="output_pair_ids"></a> [pair\_ids](#output\_pair\_ids) | ID of each written KV pair, keyed by the same keys as var.pairs. |
| <a name="output_pairs"></a> [pairs](#output\_pairs) | Full cloudflare\_workers\_kv objects, keyed by the same keys as var.pairs. |
<!-- END_TF_DOCS -->
