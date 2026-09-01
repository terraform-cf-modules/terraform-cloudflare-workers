# Submodule: hyperdrive

Hyperdrive connection pools in front of an existing PostgreSQL or MySQL origin, so a Worker can talk to a
regional database without paying the connection setup cost on every request.

```hcl
module "hyperdrive" {
  source  = "terraform-cf-modules/workers/cloudflare//modules/hyperdrive"
  version = "~> 0.1"

  account_id = var.account_id

  configs = {
    primary = {
      name = "api-primary"

      origin = {
        database = "appdb"
        scheme   = "postgres"
        user     = "app"
        password = var.origin_password
        host     = "db.internal.example.com"
        port     = 5432
      }

      origin_connection_limit = 20

      caching = {
        max_age                = 60
        stale_while_revalidate = 15
      }
    }
  }
}
```

Reach the origin directly (`host` and `port`), through Cloudflare Access (`access_client_id` and
`access_client_secret`), or through a Workers VPC service (`service_id`).

Bind a configuration to a Worker with its ID:

```hcl
bindings = {
  HYPERDRIVE = { type = "hyperdrive", id = module.hyperdrive.config_ids["primary"] }
}
```

`origin.password` is the origin database password, not a Cloudflare credential. The API never returns it, so
Terraform cannot detect drift on it, and whatever you pass is written to Terraform state. Source it from a secret
manager.

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
| [cloudflare_hyperdrive_config.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/hyperdrive_config) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Cloudflare account ID that owns the Hyperdrive configurations. | `string` | `null` | no |
| <a name="input_configs"></a> [configs](#input\_configs) | Hyperdrive configurations to create, keyed by a stable identifier.<br/><br/>`origin.password` is the password of the origin database, not a Cloudflare credential. The Cloudflare API never<br/>returns it, so Terraform cannot detect drift on it. Source it from a secret manager rather than a literal, and<br/>keep in mind that whatever you pass ends up in Terraform state.<br/><br/>Reach the origin either directly (`host` and `port`), through Cloudflare Access (`access_client_id` and<br/>`access_client_secret`), or through a Workers VPC service (`service_id`). | <pre>map(object({<br/>    name = string<br/><br/>    origin = object({<br/>      database             = string<br/>      scheme               = string<br/>      user                 = string<br/>      password             = string<br/>      host                 = optional(string)<br/>      port                 = optional(number)<br/>      access_client_id     = optional(string)<br/>      access_client_secret = optional(string)<br/>      service_id           = optional(string)<br/>    })<br/><br/>    origin_connection_limit = optional(number)<br/><br/>    caching = optional(object({<br/>      disabled               = optional(bool)<br/>      max_age                = optional(number)<br/>      stale_while_revalidate = optional(number)<br/>    }))<br/><br/>    mtls = optional(object({<br/>      ca_certificate_id   = optional(string)<br/>      mtls_certificate_id = optional(string)<br/>      sslmode             = optional(string)<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether to create the resources managed by this submodule. | `bool` | `true` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_config_ids"></a> [config\_ids](#output\_config\_ids) | ID of each created Hyperdrive configuration, keyed by the same keys as var.configs. |
| <a name="output_configs"></a> [configs](#output\_configs) | Full cloudflare\_hyperdrive\_config objects, keyed by the same keys as var.configs. Contains the origin credentials. |
| <a name="output_enabled"></a> [enabled](#output\_enabled) | Whether this submodule created its resources. |
<!-- END_TF_DOCS -->
