# Submodule: d1

D1 serverless SQL databases.

```hcl
module "d1" {
  source  = "terraform-cf-modules/workers/cloudflare//modules/d1"
  version = "~> 0.1"

  account_id = var.account_id

  databases = {
    app = {
      name                  = "api-app"
      primary_location_hint = "weur"
      read_replication_mode = "auto"
    }
  }
}
```

`primary_location_hint` places the primary replica (`wnam`, `enam`, `weur`, `eeur`, `apac`, `oc`).
`jurisdiction` (`eu`, `fedramp`, `us`) pins storage to a data boundary and, when set, Cloudflare ignores the
location hint.

Bind a database to a Worker with its UUID:

```hcl
bindings = {
  DB = { type = "d1", database_id = module.d1.database_ids["app"] }
}
```

This submodule creates databases; it does not run schema migrations.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Cloudflare account ID that owns the D1 databases. | `string` | `null` | no |
| <a name="input_databases"></a> [databases](#input\_databases) | D1 databases to create, keyed by a stable identifier.<br/><br/>`primary_location_hint` places the primary replica. `jurisdiction` pins storage to a data boundary and, when<br/>set, Cloudflare ignores the location hint. `read_replication_mode` turns global read replicas on or off. | <pre>map(object({<br/>    name                  = string<br/>    primary_location_hint = optional(string)<br/>    jurisdiction          = optional(string)<br/>    read_replication_mode = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether to create the resources managed by this submodule. | `bool` | `true` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_database_ids"></a> [database\_ids](#output\_database\_ids) | UUID of each created D1 database, keyed by the same keys as var.databases. |
| <a name="output_database_names"></a> [database\_names](#output\_database\_names) | Name of each created D1 database, keyed by the same keys as var.databases. |
| <a name="output_databases"></a> [databases](#output\_databases) | Full cloudflare\_d1\_database objects, keyed by the same keys as var.databases. |
| <a name="output_enabled"></a> [enabled](#output\_enabled) | Whether this submodule created its resources. |
<!-- END_TF_DOCS -->
