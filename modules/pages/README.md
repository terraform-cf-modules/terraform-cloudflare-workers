# Submodule: pages

Pages projects and their custom domains.

Pages Functions run on the Workers runtime and bind to the same storage products, but the API takes those
bindings in a different shape: one map per binding kind on each environment, rather than one list with a `type`
discriminator. This submodule takes the flat form and translates it.

```hcl
module "pages" {
  source  = "terraform-cf-modules/workers/cloudflare//modules/pages"
  version = "~> 0.1"

  account_id = var.account_id

  projects = {
    site = {
      name              = "example-site"
      production_branch = "main"

      build_config = {
        build_command   = "npm run build"
        destination_dir = "dist"
      }

      source = {
        type                       = "github"
        owner                      = "example-org"
        repo_name                  = "example-site"
        preview_deployment_setting = "custom"
        preview_branch_includes    = ["develop"]
      }

      production = {
        compatibility_date = "2025-06-01"

        kv_namespaces = { SESSIONS = var.namespace_id }
        d1_databases  = { CONTENT = var.database_id }

        env_vars = {
          NODE_VERSION = { type = "plain_text", value = "20" }
        }
      }
    }
  }

  domains = {
    www = { name = "www.example.com", project_key = "site" }
  }
}
```

`preview` and `production` take the same shape. Binding maps are keyed by the name the Function sees:
`kv_namespaces`, `d1_databases`, `hyperdrive_bindings`, `vectorize_bindings`, `mtls_certificates`,
`analytics_engine_datasets`, `queue_producers`, `ai_bindings` and `durable_object_namespaces` map a name to an
identifier; `r2_buckets` and `services` map a name to a small object; `browsers` is a set of names.

Environment variables of type `secret_text` are written to Terraform state in plain text.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Cloudflare account ID that owns the Pages projects. | `string` | `null` | no |
| <a name="input_domains"></a> [domains](#input\_domains) | Custom domains attached to a Pages project, keyed by a stable identifier.<br/><br/>Set `project_key` to attach to a project created by this submodule, or `project_name` to attach to an existing<br/>one. Exactly one of the two must be set. | <pre>map(object({<br/>    name         = string<br/>    project_key  = optional(string)<br/>    project_name = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether to create the resources managed by this submodule. | `bool` | `true` | no |
| <a name="input_projects"></a> [projects](#input\_projects) | Pages projects to create, keyed by a stable identifier.<br/><br/>`source` connects the project to a git provider so pushes trigger builds. Leave it null for a project you<br/>deploy with Wrangler or the API.<br/><br/>`preview` and `production` carry the per environment Functions configuration: bindings, environment variables,<br/>compatibility settings and limits. Both take the same shape.<br/><br/>Environment variables of type `secret_text` are stored in Terraform state in plain text. | <pre>map(object({<br/>    name              = string<br/>    production_branch = string<br/><br/>    build_config = optional(object({<br/>      build_command       = optional(string)<br/>      destination_dir     = optional(string)<br/>      root_dir            = optional(string)<br/>      build_caching       = optional(bool)<br/>      web_analytics_tag   = optional(string)<br/>      web_analytics_token = optional(string)<br/>    }))<br/><br/>    source = optional(object({<br/>      type                           = string<br/>      owner                          = optional(string)<br/>      repo_name                      = optional(string)<br/>      production_branch              = optional(string)<br/>      production_deployments_enabled = optional(bool)<br/>      pr_comments_enabled            = optional(bool)<br/>      preview_deployment_setting     = optional(string)<br/>      preview_branch_includes        = optional(list(string))<br/>      preview_branch_excludes        = optional(list(string))<br/>      path_includes                  = optional(list(string))<br/>      path_excludes                  = optional(list(string))<br/>    }))<br/><br/>    preview = optional(object({<br/>      compatibility_date                   = optional(string)<br/>      compatibility_flags                  = optional(list(string))<br/>      always_use_latest_compatibility_date = optional(bool)<br/>      build_image_major_version            = optional(number)<br/>      fail_open                            = optional(bool)<br/>      placement_mode                       = optional(string)<br/>      cpu_ms                               = optional(number)<br/><br/>      env_vars                  = optional(map(object({ type = string, value = string })), {})<br/>      kv_namespaces             = optional(map(string), {})<br/>      d1_databases              = optional(map(string), {})<br/>      hyperdrive_bindings       = optional(map(string), {})<br/>      vectorize_bindings        = optional(map(string), {})<br/>      mtls_certificates         = optional(map(string), {})<br/>      analytics_engine_datasets = optional(map(string), {})<br/>      queue_producers           = optional(map(string), {})<br/>      ai_bindings               = optional(map(string), {})<br/>      durable_object_namespaces = optional(map(string), {})<br/>      browsers                  = optional(set(string), [])<br/>      r2_buckets                = optional(map(object({ name = string, jurisdiction = optional(string) })), {})<br/>      services = optional(map(object({<br/>        service     = string<br/>        environment = optional(string)<br/>        entrypoint  = optional(string)<br/>      })), {})<br/>    }))<br/><br/>    production = optional(object({<br/>      compatibility_date                   = optional(string)<br/>      compatibility_flags                  = optional(list(string))<br/>      always_use_latest_compatibility_date = optional(bool)<br/>      build_image_major_version            = optional(number)<br/>      fail_open                            = optional(bool)<br/>      placement_mode                       = optional(string)<br/>      cpu_ms                               = optional(number)<br/><br/>      env_vars                  = optional(map(object({ type = string, value = string })), {})<br/>      kv_namespaces             = optional(map(string), {})<br/>      d1_databases              = optional(map(string), {})<br/>      hyperdrive_bindings       = optional(map(string), {})<br/>      vectorize_bindings        = optional(map(string), {})<br/>      mtls_certificates         = optional(map(string), {})<br/>      analytics_engine_datasets = optional(map(string), {})<br/>      queue_producers           = optional(map(string), {})<br/>      ai_bindings               = optional(map(string), {})<br/>      durable_object_namespaces = optional(map(string), {})<br/>      browsers                  = optional(set(string), [])<br/>      r2_buckets                = optional(map(object({ name = string, jurisdiction = optional(string) })), {})<br/>      services = optional(map(object({<br/>        service     = string<br/>        environment = optional(string)<br/>        entrypoint  = optional(string)<br/>      })), {})<br/>    }))<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_domain_ids"></a> [domain\_ids](#output\_domain\_ids) | ID of each created Pages domain, keyed by the same keys as var.domains. |
| <a name="output_domains"></a> [domains](#output\_domains) | Full cloudflare\_pages\_domain objects, keyed by the same keys as var.domains. |
| <a name="output_enabled"></a> [enabled](#output\_enabled) | Whether this submodule created its resources. |
| <a name="output_project_ids"></a> [project\_ids](#output\_project\_ids) | ID of each created Pages project, keyed by the same keys as var.projects. |
| <a name="output_project_subdomains"></a> [project\_subdomains](#output\_project\_subdomains) | The pages.dev subdomain of each created Pages project, keyed by the same keys as var.projects. |
| <a name="output_projects"></a> [projects](#output\_projects) | Full cloudflare\_pages\_project objects, keyed by the same keys as var.projects. Contains environment variable values. |
<!-- END_TF_DOCS -->
