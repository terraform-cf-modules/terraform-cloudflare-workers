# Wrapper

Creates many Workers from a single map, so a fleet of similar Workers does not need a repeated `module` block
per item. Every root module input is available in `defaults` and can be overridden per item.

```hcl
module "instances" {
  source = "terraform-cf-modules/workers/cloudflare//wrappers"

  defaults = {
    account_id         = var.account_id
    zone_id            = var.zone_id
    compatibility_date = "2025-06-01"
  }

  items = {
    api = {
      script_name = "api"
      content     = file("${path.module}/api.js")
      routes      = { main = { pattern = "example.com/api/*" } }
    }
    nightly = {
      script_name    = "nightly"
      content        = file("${path.module}/nightly.js")
      cron_schedules = ["0 3 * * *"]
    }
  }
}
```

Keys in `items` become the state addresses, so keep them stable. Renaming a key destroys and recreates that
instance.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.12.0 |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | ~> 5.24 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_wrapper"></a> [wrapper](#module\_wrapper) | ../ | n/a |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_defaults"></a> [defaults](#input\_defaults) | Values applied to every item unless the item overrides them. | `any` | `{}` | no |
| <a name="input_items"></a> [items](#input\_items) | Map of module instances to create, keyed by a stable identifier. | `any` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_script_names"></a> [script\_names](#output\_script\_names) | Name of the Worker created for each item. |
| <a name="output_wrapper"></a> [wrapper](#output\_wrapper) | Map of module outputs, keyed by the same keys as var.items. |
<!-- END_TF_DOCS -->
