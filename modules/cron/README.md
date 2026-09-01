# Submodule: cron

Scheduled invocations of a Worker's `scheduled` handler.

One `cloudflare_workers_cron_trigger` owns the complete schedule list for a script: whatever it does not contain
is removed from Cloudflare. Put all of a Worker's schedules in one entry. The submodule rejects two entries that
name the same script rather than letting them fight over the same API object.

```hcl
module "cron" {
  source  = "terraform-cf-modules/workers/cloudflare//modules/cron"
  version = "~> 0.1"

  account_id = var.account_id

  triggers = {
    api = {
      script_name = "api"
      schedules   = ["*/15 * * * *", "0 3 * * *"]
    }
  }
}
```

Schedules are five field cron expressions in UTC, or one of `@hourly`, `@daily`, `@weekly`, `@monthly`,
`@yearly`.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Cloudflare account ID that owns the Workers. | `string` | `null` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether to create the resources managed by this submodule. | `bool` | `true` | no |
| <a name="input_triggers"></a> [triggers](#input\_triggers) | Cron triggers, keyed by a stable identifier.<br/><br/>One resource holds every schedule for a script, so a second entry for the same `script_name` overwrites the<br/>first. Put all of a Worker's schedules in one entry.<br/><br/>Cloudflare accepts standard five field cron expressions in UTC, plus the `@hourly`, `@daily`, `@weekly`,<br/>`@monthly` and `@yearly` shorthands. | <pre>map(object({<br/>    script_name = string<br/>    schedules   = list(string)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_enabled"></a> [enabled](#output\_enabled) | Whether this submodule created its resources. |
| <a name="output_trigger_ids"></a> [trigger\_ids](#output\_trigger\_ids) | ID of each created cron trigger, keyed by the same keys as var.triggers. |
| <a name="output_triggers"></a> [triggers](#output\_triggers) | Full cloudflare\_workers\_cron\_trigger objects, keyed by the same keys as var.triggers. |
<!-- END_TF_DOCS -->
