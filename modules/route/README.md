# Submodule: route

The two ways traffic reaches a Worker from a zone you own.

`cloudflare_workers_route` matches a URL pattern on an existing zone. `cloudflare_workers_custom_domain` takes a
whole hostname and provisions its certificate.

```hcl
module "route" {
  source  = "terraform-cf-modules/workers/cloudflare//modules/route"
  version = "~> 0.1"

  account_id = var.account_id
  zone_id    = var.zone_id

  routes = {
    api    = { pattern = "example.com/api/*", script = "api" }
    bypass = { pattern = "example.com/static/*" } # no script: skip Workers for this path
  }

  custom_domains = {
    api = { hostname = "api.example.com", service = "api" }
  }
}
```

Route patterns are written without a scheme (`example.com/api/*`, not `https://example.com/api/*`), and the
submodule rejects the scheme form rather than letting the API do it.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Cloudflare account ID that owns the Workers. Required for custom domains. | `string` | `null` | no |
| <a name="input_custom_domains"></a> [custom\_domains](#input\_custom\_domains) | Worker custom domains, keyed by a stable identifier.<br/><br/>A custom domain routes every request for a hostname to a Worker and provisions its certificate. Unlike a<br/>route, it takes the whole hostname rather than a URL pattern. | <pre>map(object({<br/>    hostname  = string<br/>    service   = string<br/>    zone_id   = optional(string)<br/>    zone_name = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether to create the resources managed by this submodule. | `bool` | `true` | no |
| <a name="input_routes"></a> [routes](#input\_routes) | Worker routes, keyed by a stable identifier.<br/><br/>A route hangs off a zone and matches request URLs by pattern, for example `example.com/api/*`. Leave `script`<br/>null to create a route that explicitly bypasses Workers for that pattern. | <pre>map(object({<br/>    pattern = string<br/>    script  = optional(string)<br/>    zone_id = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | Default Cloudflare zone ID for routes and custom domains that do not set their own. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_custom_domain_ids"></a> [custom\_domain\_ids](#output\_custom\_domain\_ids) | ID of each created custom domain, keyed by the same keys as var.custom\_domains. |
| <a name="output_custom_domains"></a> [custom\_domains](#output\_custom\_domains) | Full cloudflare\_workers\_custom\_domain objects, keyed by the same keys as var.custom\_domains. |
| <a name="output_enabled"></a> [enabled](#output\_enabled) | Whether this submodule created its resources. |
| <a name="output_route_ids"></a> [route\_ids](#output\_route\_ids) | ID of each created route, keyed by the same keys as var.routes. |
| <a name="output_routes"></a> [routes](#output\_routes) | Full cloudflare\_workers\_route objects, keyed by the same keys as var.routes. |
<!-- END_TF_DOCS -->
