<p align="center">
  <img width="1000" alt="CloudDrove Banner" src="https://clouddrove.s3.ca-central-1.amazonaws.com/img/clouddrove-github-cover.png" />
</p>

<h1 align="center">Cloudflare Workers</h1>
<p align="center"><em>Workers, routes, cron triggers, and the developer platform storage bindings (KV, D1, Queues, R2, Hyperdrive) plus Pages.</em></p>

<p align="center">
  <a href="https://www.terraform.io"><img src="https://img.shields.io/badge/terraform-%3E%3D%201.12-844FBA?logo=terraform&logoColor=white" alt="Terraform" /></a>
  <a href="https://opentofu.org"><img src="https://img.shields.io/badge/opentofu-%3E%3D%201.12-FFDA18?logo=opentofu&logoColor=black" alt="OpenTofu" /></a>
  <a href="https://registry.terraform.io/providers/cloudflare/cloudflare/latest"><img src="https://img.shields.io/badge/provider-cloudflare%20~%3E%205.24-F38020?logo=cloudflare&logoColor=white" alt="Cloudflare Provider" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg" alt="License" /></a>
</p>

---

Deploys a Cloudflare Worker together with everything that has to exist around it: the routes and custom domains
that send traffic to it, the cron triggers that wake it on a schedule, and the KV namespaces, D1 databases,
Queues, R2 buckets and Hyperdrive configurations it reads and writes.

The binding wiring is the point. Getting a Worker bound to a KV namespace, a D1 database, an R2 bucket and a
queue by hand means copying namespace IDs and database UUIDs out of one resource and into a list of untyped
binding objects on another, in the right shape for each binding type. Here you name the JavaScript variable once,
next to the storage that backs it, and the module builds the binding list.

```hcl
module "worker" {
  source  = "terraform-cf-modules/workers/cloudflare"
  version = "~> 0.1"

  account_id         = var.account_id
  zone_id            = var.zone_id
  script_name        = "api"
  compatibility_date = "2025-06-01"
  content            = file("${path.module}/worker.js")

  kv_namespaces = {
    cache = { title = "api-cache", binding = "CACHE" }   # env.CACHE
  }

  d1_databases = {
    app = { name = "api-app", binding = "DB" }           # env.DB
  }

  r2_buckets = {
    uploads = { name = "api-uploads", binding = "UPLOADS" }
  }

  queues = {
    jobs = {
      queue_name = "api-jobs"
      binding    = "JOBS"                                 # producer binding
      consumer   = { type = "worker" }                    # this Worker consumes it
    }
  }

  routes = {
    api = { pattern = "example.com/api/*" }
  }

  cron_schedules = ["*/15 * * * *"]
}
```

---

## What it creates

| Terraform resource | Created by |
|--------------------|------------|
| `cloudflare_workers_script`, `cloudflare_workers_script_subdomain` | `modules/script` (default model) |
| `cloudflare_worker`, `cloudflare_worker_version`, `cloudflare_workers_deployment` | `modules/script` (`deployment_model = "versioned"`) |
| `cloudflare_workers_route`, `cloudflare_workers_custom_domain` | `modules/route` |
| `cloudflare_workers_cron_trigger` | `modules/cron` |
| `cloudflare_workers_kv_namespace`, `cloudflare_workers_kv` | `modules/kv` |
| `cloudflare_d1_database` | `modules/d1` |
| `cloudflare_queue`, `cloudflare_queue_consumer` | `modules/queue` |
| `cloudflare_r2_bucket` and its CORS, lifecycle, lock, event notification and custom domain resources | `modules/r2` |
| `cloudflare_hyperdrive_config` | `modules/hyperdrive` |
| `cloudflare_pages_project`, `cloudflare_pages_domain` | `modules/pages` |

`docs/architecture.md` has the full map, the reasoning behind the two deployment models, and the provider quirks
worth knowing before you hit them.

---

## Usage

### Root module

The root module is the common case: one Worker, its storage, its routes and its schedule.

```hcl
module "worker" {
  source  = "terraform-cf-modules/workers/cloudflare"
  version = "~> 0.1"

  account_id  = var.account_id
  script_name = "hello"
  content     = file("${path.module}/worker.js")

  workers_dev = { enabled = true }
}
```

### Submodules

Use these when the pieces are owned separately: storage in a platform configuration, Workers in a team one.

```hcl
module "namespaces" {
  source  = "terraform-cf-modules/workers/cloudflare//modules/kv"
  version = "~> 0.1"

  account_id = var.account_id
  namespaces = {
    sessions = { title = "sessions" }
  }
}

module "worker" {
  source  = "terraform-cf-modules/workers/cloudflare//modules/script"
  version = "~> 0.1"

  account_id  = var.account_id
  script_name = "hello"
  content     = file("${path.module}/worker.js")

  bindings = {
    SESSIONS = {
      type         = "kv_namespace"
      namespace_id = module.namespaces.namespace_ids["sessions"]
    }
  }
}
```

Available submodules: `script`, `route`, `cron`, `kv`, `d1`, `queue`, `r2`, `hyperdrive`, `pages`.

### Wrapper for many Workers

```hcl
module "workers" {
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

---

## Bindings

Every binding is a key in a map. The key is the name the Worker sees on `env`, and `type` decides which other
field the API reads.

| Binding source | How you declare it |
|----------------|--------------------|
| KV namespace this module creates | `kv_namespaces = { cache = { title = "...", binding = "CACHE" } }` |
| D1 database this module creates | `d1_databases = { app = { name = "...", binding = "DB" } }` |
| Queue this module creates | `queues = { jobs = { queue_name = "...", binding = "JOBS" } }` |
| R2 bucket this module creates | `r2_buckets = { uploads = { name = "...", binding = "UPLOADS" } }` |
| Hyperdrive config this module creates | `hyperdrive_configs = { db = { ..., binding = "HYPERDRIVE" } }` |
| Anything else | `bindings = { NAME = { type = "...", ... } }` |

Anything the module did not create goes in `bindings`, in the provider's own shape:

```hcl
bindings = {
  ENVIRONMENT   = { type = "plain_text", text = "production" }
  FEATURE_FLAGS = { type = "json", json = jsonencode({ newCheckout = true }) }
  AI            = { type = "ai" }
  UPSTREAM      = { type = "service", service = "other-worker" }
  COUNTER       = { type = "durable_object_namespace", class_name = "Counter" }
  THROTTLE      = { type = "ratelimit", simple = { limit = 100, period = 60 } }
  SESSIONS      = { type = "kv_namespace", namespace_id = var.existing_namespace_id }
}
```

A key in `bindings` that collides with a name derived from the storage maps is rejected at plan time rather than
silently overwriting one of the two.

`secret_text`, `key_base64` and `key_jwk` binding values are written to Terraform state in plain text. For real
secrets use a `secrets_store_secret` binding (`store_id`, `secret_name`), or set the secret outside Terraform and
add `keep_bindings = ["secret_text"]` so uploads do not wipe it.

---

## Examples

| Example | What it shows |
|---------|---------------|
| [`examples/basic`](examples/basic) | one Worker on its workers.dev subdomain |
| [`examples/complete`](examples/complete) | every optional feature, all five storage products, Pages |
| [`examples/bindings`](examples/bindings) | derived bindings against hand written bindings, and triggers pointed at a Worker built elsewhere |
| [`examples/pages`](examples/pages) | a Pages project with git integration, custom domain and Functions bindings |

---

## Repository layout

```
terraform.tf          provider and version requirements
main.tf               root module composition
variables.tf          root module inputs
outputs.tf            root module outputs
locals.tf             the binding derivation
modules/<name>/       composable building blocks, same file layout
examples/             runnable examples
wrappers/             for_each wrapper for many Workers
tests/                native terraform test files
docs/                 architecture notes
```

---

## Local development

```bash
pre-commit install

make fmt        # terraform fmt -recursive
make validate   # init and validate every directory
make lint       # tflint
make docs       # regenerate the terraform-docs blocks
make test       # mocked terraform test, no credentials needed
make security   # trivy, checkov, gitleaks
make ci         # all of the above
```

`make test` runs against `mock_provider`, so it needs no Cloudflare credentials. The live tests in
`tests/integration.tftest.hcl` run only on schedule and manual dispatch.

---

## CI

Most workflows call the shared, actively maintained
[clouddrove/github-shared-workflows](https://github.com/clouddrove/github-shared-workflows) at `@v2`, so the
standard changes in one place for every repository.

| Workflow | Source | Purpose |
|----------|--------|---------|
| `tf-checks` | shared | init and validate both examples |
| `tflint` | shared | lint |
| `checkov` | shared | policy scan |
| `gitleaks` | shared | secret scan |
| `pr_checks` | shared | Conventional Commit pull request title |
| `auto_assignee` | shared | reviewer assignment |
| `automerge` | shared | auto merge on green |
| `stale_pr` | shared | stale handling |
| `readme` | shared | rebuild README from README.yaml |
| `tag-release` | shared | tag and changelog on merge |
| `opentofu` | local | OpenTofu compatibility, no shared equivalent yet |
| `test` | local | `terraform test` with mocked provider |
| `integration` | local | live apply against a test account, scheduled only |

### Required organisation secrets

| Secret | Used by |
|--------|---------|
| `GITHUB` | `tflint`, `tag-release`, `auto_assignee`, `automerge`, `readme` |
| `SLACK_WEBHOOK_TERRAFORM` | `readme` |
| `CLOUDFLARE_API_TOKEN` | `integration` |
| `CLOUDFLARE_TEST_ACCOUNT_ID` | `integration` |
| `CLOUDFLARE_TEST_ZONE_ID` | `integration` |

The API token needs `Workers Scripts Read` and `Workers Scripts Write`, plus `Workers KV Storage`, `D1`,
`Queues`, `Workers R2 Storage`, `Hyperdrive` and `Pages` permissions for whichever parts of the module you use.

---

## Inputs and outputs

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.12.0 |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | ~> 5.24 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_cron"></a> [cron](#module\_cron) | ./modules/cron | n/a |
| <a name="module_d1"></a> [d1](#module\_d1) | ./modules/d1 | n/a |
| <a name="module_hyperdrive"></a> [hyperdrive](#module\_hyperdrive) | ./modules/hyperdrive | n/a |
| <a name="module_kv"></a> [kv](#module\_kv) | ./modules/kv | n/a |
| <a name="module_pages"></a> [pages](#module\_pages) | ./modules/pages | n/a |
| <a name="module_queue"></a> [queue](#module\_queue) | ./modules/queue | n/a |
| <a name="module_r2"></a> [r2](#module\_r2) | ./modules/r2 | n/a |
| <a name="module_route"></a> [route](#module\_route) | ./modules/route | n/a |
| <a name="module_script"></a> [script](#module\_script) | ./modules/script | n/a |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Cloudflare account ID that owns the resources. Required for account scoped resources. | `string` | `null` | no |
| <a name="input_assets"></a> [assets](#input\_assets) | Static assets served in front of the Worker. `directory` is a path on the machine running Terraform. | <pre>object({<br/>    directory = optional(string)<br/>    jwt       = optional(string)<br/>    config = optional(object({<br/>      headers            = optional(string)<br/>      redirects          = optional(string)<br/>      html_handling      = optional(string)<br/>      not_found_handling = optional(string)<br/>      run_worker_first   = optional(any)<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_bindings"></a> [bindings](#input\_bindings) | Extra Worker bindings that this module does not derive automatically, keyed by the variable name the Worker<br/>sees. Storage created through `kv_namespaces`, `d1_databases`, `queues`, `r2_buckets` and `hyperdrive_configs`<br/>is bound for you; use this map for `plain_text`, `json`, `service`, `durable_object_namespace`, `ai`,<br/>`browser`, `vectorize` and anything else.<br/><br/>See modules/script/README.md for the field each binding type expects. | <pre>map(object({<br/>    type = string<br/><br/>    algorithm                     = optional(string)<br/>    allowed_destination_addresses = optional(list(string))<br/>    allowed_sender_addresses      = optional(list(string))<br/>    app_id                        = optional(string)<br/>    bucket_name                   = optional(string)<br/>    certificate_id                = optional(string)<br/>    class_name                    = optional(string)<br/>    database_id                   = optional(string)<br/>    dataset                       = optional(string)<br/>    destination_address           = optional(string)<br/>    dispatch_namespace            = optional(string)<br/>    entrypoint                    = optional(string)<br/>    environment                   = optional(string)<br/>    format                        = optional(string)<br/>    id                            = optional(string)<br/>    index_name                    = optional(string)<br/>    instance_name                 = optional(string)<br/>    json                          = optional(string)<br/>    jurisdiction                  = optional(string)<br/>    key_base64                    = optional(string)<br/>    key_jwk                       = optional(string)<br/>    namespace                     = optional(string)<br/>    namespace_id                  = optional(string)<br/>    network_id                    = optional(string)<br/>    old_name                      = optional(string)<br/>    part                          = optional(string)<br/>    pipeline                      = optional(string)<br/>    queue_name                    = optional(string)<br/>    script_name                   = optional(string)<br/>    secret_name                   = optional(string)<br/>    service                       = optional(string)<br/>    service_id                    = optional(string)<br/>    store_id                      = optional(string)<br/>    text                          = optional(string)<br/>    tunnel_id                     = optional(string)<br/>    usages                        = optional(set(string))<br/>    version_id                    = optional(string)<br/>    workflow_name                 = optional(string)<br/><br/>    outbound = optional(object({<br/>      params = optional(list(string))<br/>      worker = optional(object({<br/>        environment = optional(string)<br/>        service     = optional(string)<br/>      }))<br/>    }))<br/><br/>    simple = optional(object({<br/>      limit              = number<br/>      period             = number<br/>      mitigation_timeout = optional(number)<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_body_part"></a> [body\_part](#input\_body\_part) | Entrypoint part name for a legacy service worker format Worker. Mutually exclusive with main\_module. | `string` | `null` | no |
| <a name="input_compatibility_date"></a> [compatibility\_date](#input\_compatibility\_date) | Runtime compatibility date, for example 2025-01-01. | `string` | `null` | no |
| <a name="input_compatibility_flags"></a> [compatibility\_flags](#input\_compatibility\_flags) | Runtime compatibility flags, for example ["nodejs\_compat"]. | `set(string)` | `null` | no |
| <a name="input_content"></a> [content](#input\_content) | Worker source code, inline. Mutually exclusive with content\_file. | `string` | `null` | no |
| <a name="input_content_file"></a> [content\_file](#input\_content\_file) | Path to a file holding the Worker source code. Mutually exclusive with content. | `string` | `null` | no |
| <a name="input_content_sha256"></a> [content\_sha256](#input\_content\_sha256) | SHA-256 of the Worker source. Set it alongside content\_file so Terraform notices changes to the file. | `string` | `null` | no |
| <a name="input_content_type"></a> [content\_type](#input\_content\_type) | Content type of the uploaded module, for example application/javascript+module. | `string` | `null` | no |
| <a name="input_cron_schedules"></a> [cron\_schedules](#input\_cron\_schedules) | Cron schedules that invoke this Worker's scheduled handler, in UTC. Five field cron expressions, or one of<br/>@hourly, @daily, @weekly, @monthly, @yearly. Empty means no cron trigger. | `list(string)` | `[]` | no |
| <a name="input_custom_domains"></a> [custom\_domains](#input\_custom\_domains) | Worker custom domains, keyed by a stable identifier. `service` defaults to the Worker this module deploys. | <pre>map(object({<br/>    hostname  = string<br/>    service   = optional(string)<br/>    zone_id   = optional(string)<br/>    zone_name = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_d1_databases"></a> [d1\_databases](#input\_d1\_databases) | D1 databases to create, keyed by a stable identifier. Set `binding` to the variable name the Worker should<br/>see, or leave it null to create the database without binding it. | <pre>map(object({<br/>    name                  = string<br/>    primary_location_hint = optional(string)<br/>    jurisdiction          = optional(string)<br/>    read_replication_mode = optional(string)<br/>    binding               = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_deployment_message"></a> [deployment\_message](#input\_deployment\_message) | Human readable message recorded against the deployment. Only used when deployment\_model is `versioned`. | `string` | `null` | no |
| <a name="input_deployment_model"></a> [deployment\_model](#input\_deployment\_model) | Which provider resources back the Worker.<br/><br/>  * `script`    - a single `cloudflare_workers_script`. Stable and generally available. The default.<br/>  * `versioned` - `cloudflare_worker` plus `cloudflare_worker_version` plus `cloudflare_workers_deployment`.<br/>                  Beta in the provider. Use it when you need versions and gradual deployments.<br/><br/>docs/architecture.md explains the trade off. | `string` | `"script"` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether to create the resources managed by this module. Set to false to disable the module without removing the block. | `bool` | `true` | no |
| <a name="input_hyperdrive_configs"></a> [hyperdrive\_configs](#input\_hyperdrive\_configs) | Hyperdrive configurations to create, keyed by a stable identifier. Set `binding` to the variable name the<br/>Worker should see.<br/><br/>`origin.password` is the origin database password, not a Cloudflare credential. It is written to Terraform<br/>state and the API never returns it, so Terraform cannot detect drift on it. | <pre>map(object({<br/>    name    = string<br/>    binding = optional(string)<br/><br/>    origin = object({<br/>      database             = string<br/>      scheme               = string<br/>      user                 = string<br/>      password             = string<br/>      host                 = optional(string)<br/>      port                 = optional(number)<br/>      access_client_id     = optional(string)<br/>      access_client_secret = optional(string)<br/>      service_id           = optional(string)<br/>    })<br/><br/>    origin_connection_limit = optional(number)<br/><br/>    caching = optional(object({<br/>      disabled               = optional(bool)<br/>      max_age                = optional(number)<br/>      stale_while_revalidate = optional(number)<br/>    }))<br/><br/>    mtls = optional(object({<br/>      ca_certificate_id   = optional(string)<br/>      mtls_certificate_id = optional(string)<br/>      sslmode             = optional(string)<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_keep_bindings"></a> [keep\_bindings](#input\_keep\_bindings) | Binding types to carry over from the deployed Worker rather than replace, for example ["secret\_text"]. | `set(string)` | `null` | no |
| <a name="input_kv_namespaces"></a> [kv\_namespaces](#input\_kv\_namespaces) | Workers KV namespaces to create, keyed by a stable identifier. Set `binding` to the variable name the Worker<br/>should see, or leave it null to create the namespace without binding it. | <pre>map(object({<br/>    title   = string<br/>    binding = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_kv_pairs"></a> [kv\_pairs](#input\_kv\_pairs) | Key/value pairs written into the namespaces above, keyed by a stable identifier. `namespace_key` references a<br/>key in var.kv\_namespaces; `namespace_id` targets a namespace created elsewhere.<br/><br/>Values are stored in Terraform state in plain text. | <pre>map(object({<br/>    key_name      = string<br/>    value         = string<br/>    namespace_key = optional(string)<br/>    namespace_id  = optional(string)<br/>    metadata      = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_limits"></a> [limits](#input\_limits) | CPU and subrequest limits for the Worker. | <pre>object({<br/>    cpu_ms      = optional(number)<br/>    subrequests = optional(number)<br/>  })</pre> | `null` | no |
| <a name="input_logpush"></a> [logpush](#input\_logpush) | Whether Workers Logpush is enabled for the Worker. | `bool` | `null` | no |
| <a name="input_main_module"></a> [main\_module](#input\_main\_module) | Entrypoint module name for an ES module Worker, for example worker.js. | `string` | `"worker.js"` | no |
| <a name="input_migrations"></a> [migrations](#input\_migrations) | Durable Object class migrations applied on upload. | <pre>object({<br/>    old_tag            = optional(string)<br/>    new_tag            = optional(string)<br/>    new_classes        = optional(list(string))<br/>    new_sqlite_classes = optional(list(string))<br/>    deleted_classes    = optional(list(string))<br/>    renamed_classes = optional(map(object({<br/>      from = string<br/>      to   = string<br/>    })), {})<br/>    transferred_classes = optional(map(object({<br/>      from        = string<br/>      from_script = string<br/>      to          = string<br/>    })), {})<br/>  })</pre> | `null` | no |
| <a name="input_modules"></a> [modules](#input\_modules) | Extra modules uploaded alongside the entrypoint, keyed by module name. Only used when deployment\_model is `versioned`. | <pre>map(object({<br/>    content_type   = string<br/>    content_file   = optional(string)<br/>    content_base64 = optional(string)<br/>    module_name    = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_observability"></a> [observability](#input\_observability) | Workers observability settings. `enabled` turns on the feature; the nested logs and traces objects tune each stream. | <pre>object({<br/>    enabled            = bool<br/>    head_sampling_rate = optional(number)<br/>    logs = optional(object({<br/>      enabled            = bool<br/>      invocation_logs    = bool<br/>      destinations       = optional(list(string))<br/>      head_sampling_rate = optional(number)<br/>      persist            = optional(bool)<br/>    }))<br/>    traces = optional(object({<br/>      enabled            = optional(bool)<br/>      destinations       = optional(list(string))<br/>      head_sampling_rate = optional(number)<br/>      persist            = optional(bool)<br/>      propagation_policy = optional(string)<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_pages_domains"></a> [pages\_domains](#input\_pages\_domains) | Custom domains attached to a Pages project, keyed by a stable identifier. | <pre>map(object({<br/>    name         = string<br/>    project_key  = optional(string)<br/>    project_name = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_pages_projects"></a> [pages\_projects](#input\_pages\_projects) | Pages projects to create, keyed by a stable identifier. Passed straight through to modules/pages. | <pre>map(object({<br/>    name              = string<br/>    production_branch = string<br/><br/>    build_config = optional(object({<br/>      build_command       = optional(string)<br/>      destination_dir     = optional(string)<br/>      root_dir            = optional(string)<br/>      build_caching       = optional(bool)<br/>      web_analytics_tag   = optional(string)<br/>      web_analytics_token = optional(string)<br/>    }))<br/><br/>    source = optional(object({<br/>      type                           = string<br/>      owner                          = optional(string)<br/>      repo_name                      = optional(string)<br/>      production_branch              = optional(string)<br/>      production_deployments_enabled = optional(bool)<br/>      pr_comments_enabled            = optional(bool)<br/>      preview_deployment_setting     = optional(string)<br/>      preview_branch_includes        = optional(list(string))<br/>      preview_branch_excludes        = optional(list(string))<br/>      path_includes                  = optional(list(string))<br/>      path_excludes                  = optional(list(string))<br/>    }))<br/><br/>    preview = optional(object({<br/>      compatibility_date                   = optional(string)<br/>      compatibility_flags                  = optional(list(string))<br/>      always_use_latest_compatibility_date = optional(bool)<br/>      build_image_major_version            = optional(number)<br/>      fail_open                            = optional(bool)<br/>      placement_mode                       = optional(string)<br/>      cpu_ms                               = optional(number)<br/><br/>      env_vars                  = optional(map(object({ type = string, value = string })), {})<br/>      kv_namespaces             = optional(map(string), {})<br/>      d1_databases              = optional(map(string), {})<br/>      hyperdrive_bindings       = optional(map(string), {})<br/>      vectorize_bindings        = optional(map(string), {})<br/>      mtls_certificates         = optional(map(string), {})<br/>      analytics_engine_datasets = optional(map(string), {})<br/>      queue_producers           = optional(map(string), {})<br/>      ai_bindings               = optional(map(string), {})<br/>      durable_object_namespaces = optional(map(string), {})<br/>      browsers                  = optional(set(string), [])<br/>      r2_buckets                = optional(map(object({ name = string, jurisdiction = optional(string) })), {})<br/>      services = optional(map(object({<br/>        service     = string<br/>        environment = optional(string)<br/>        entrypoint  = optional(string)<br/>      })), {})<br/>    }))<br/><br/>    production = optional(object({<br/>      compatibility_date                   = optional(string)<br/>      compatibility_flags                  = optional(list(string))<br/>      always_use_latest_compatibility_date = optional(bool)<br/>      build_image_major_version            = optional(number)<br/>      fail_open                            = optional(bool)<br/>      placement_mode                       = optional(string)<br/>      cpu_ms                               = optional(number)<br/><br/>      env_vars                  = optional(map(object({ type = string, value = string })), {})<br/>      kv_namespaces             = optional(map(string), {})<br/>      d1_databases              = optional(map(string), {})<br/>      hyperdrive_bindings       = optional(map(string), {})<br/>      vectorize_bindings        = optional(map(string), {})<br/>      mtls_certificates         = optional(map(string), {})<br/>      analytics_engine_datasets = optional(map(string), {})<br/>      queue_producers           = optional(map(string), {})<br/>      ai_bindings               = optional(map(string), {})<br/>      durable_object_namespaces = optional(map(string), {})<br/>      browsers                  = optional(set(string), [])<br/>      r2_buckets                = optional(map(object({ name = string, jurisdiction = optional(string) })), {})<br/>      services = optional(map(object({<br/>        service     = string<br/>        environment = optional(string)<br/>        entrypoint  = optional(string)<br/>      })), {})<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_placement_mode"></a> [placement\_mode](#input\_placement\_mode) | Smart Placement mode. Leave null to keep the default placement. | `string` | `null` | no |
| <a name="input_queues"></a> [queues](#input\_queues) | Cloudflare Queues to create, keyed by a stable identifier.<br/><br/>`binding` gives the Worker a producer binding for the queue. `consumer` additionally registers a consumer;<br/>leave `consumer.script_name` null to make the Worker this module deploys the consumer. | <pre>map(object({<br/>    queue_name               = string<br/>    delivery_delay           = optional(number)<br/>    delivery_paused          = optional(bool)<br/>    message_retention_period = optional(number)<br/>    binding                  = optional(string)<br/><br/>    consumer = optional(object({<br/>      type                  = optional(string, "worker")<br/>      script_name           = optional(string)<br/>      dead_letter_queue     = optional(string)<br/>      batch_size            = optional(number)<br/>      max_concurrency       = optional(number)<br/>      max_retries           = optional(number)<br/>      max_wait_time_ms      = optional(number)<br/>      retry_delay           = optional(number)<br/>      visibility_timeout_ms = optional(number)<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_r2_buckets"></a> [r2\_buckets](#input\_r2\_buckets) | R2 buckets to create, keyed by a stable identifier, with their CORS, lifecycle, lock, event notification and<br/>custom domain configuration. Set `binding` to the variable name the Worker should see. | <pre>map(object({<br/>    name          = string<br/>    location      = optional(string)<br/>    jurisdiction  = optional(string)<br/>    storage_class = optional(string)<br/>    binding       = optional(string)<br/><br/>    cors_rules = optional(map(object({<br/>      allowed_headers = optional(list(string))<br/>      allowed_methods = list(string)<br/>      allowed_origins = list(string)<br/>      expose_headers  = optional(list(string))<br/>      max_age_seconds = optional(number)<br/>    })), {})<br/><br/>    lifecycle_rules = optional(map(object({<br/>      enabled = optional(bool, true)<br/>      prefix  = optional(string, "")<br/><br/>      abort_multipart_uploads_after_days = optional(number)<br/><br/>      delete_objects_after_days = optional(number)<br/>      delete_objects_on_date    = optional(string)<br/><br/>      storage_class_transitions = optional(map(object({<br/>        storage_class = optional(string, "InfrequentAccess")<br/>        after_days    = optional(number)<br/>        on_date       = optional(string)<br/>      })), {})<br/>    })), {})<br/><br/>    lock_rules = optional(map(object({<br/>      enabled         = optional(bool, true)<br/>      prefix          = optional(string)<br/>      condition_type  = string<br/>      max_age_seconds = optional(number)<br/>      date            = optional(string)<br/>    })), {})<br/><br/>    event_notifications = optional(map(object({<br/>      queue_id = string<br/>      rules = map(object({<br/>        actions     = list(string)<br/>        description = optional(string)<br/>        prefix      = optional(string)<br/>        suffix      = optional(string)<br/>      }))<br/>    })), {})<br/><br/>    custom_domains = optional(map(object({<br/>      domain  = string<br/>      zone_id = string<br/>      enabled = optional(bool, true)<br/>      ciphers = optional(list(string))<br/>      min_tls = optional(string)<br/>    })), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_routes"></a> [routes](#input\_routes) | Worker routes, keyed by a stable identifier. `script` defaults to the Worker this module deploys, so a route<br/>usually only needs a pattern. | <pre>map(object({<br/>    pattern = string<br/>    script  = optional(string)<br/>    zone_id = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_script_name"></a> [script\_name](#input\_script\_name) | Name of the Worker to deploy. Leave null to create only the storage resources and skip the Worker. | `string` | `null` | no |
| <a name="input_tail_consumers"></a> [tail\_consumers](#input\_tail\_consumers) | Other Workers that receive this Worker's tail events, keyed by a stable identifier. | <pre>map(object({<br/>    service     = string<br/>    environment = optional(string)<br/>    namespace   = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_usage_model"></a> [usage\_model](#input\_usage\_model) | Billing usage model for the Worker. | `string` | `null` | no |
| <a name="input_version_message"></a> [version\_message](#input\_version\_message) | Human readable message recorded against the uploaded version. Only used when deployment\_model is `versioned`. | `string` | `null` | no |
| <a name="input_version_tag"></a> [version\_tag](#input\_version\_tag) | Caller supplied identifier recorded against the uploaded version. Only used when deployment\_model is `versioned`. | `string` | `null` | no |
| <a name="input_worker_tags"></a> [worker\_tags](#input\_worker\_tags) | Tags attached to the Worker. Only used when deployment\_model is `versioned`. | `set(string)` | `null` | no |
| <a name="input_workers_dev"></a> [workers\_dev](#input\_workers\_dev) | workers.dev subdomain settings. Leave null to leave the subdomain untouched. | <pre>object({<br/>    enabled          = bool<br/>    previews_enabled = optional(bool)<br/>  })</pre> | `null` | no |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | Cloudflare zone ID that owns the resources. Required for zone scoped resources. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_bindings"></a> [bindings](#output\_bindings) | The binding map handed to the Worker, including the entries derived from the storage this module created. |
| <a name="output_cron_triggers"></a> [cron\_triggers](#output\_cron\_triggers) | Full cloudflare\_workers\_cron\_trigger objects, keyed by the Worker name. |
| <a name="output_custom_domains"></a> [custom\_domains](#output\_custom\_domains) | Full cloudflare\_workers\_custom\_domain objects, keyed by the same keys as var.custom\_domains. |
| <a name="output_d1_database_ids"></a> [d1\_database\_ids](#output\_d1\_database\_ids) | UUID of each created D1 database, keyed by the same keys as var.d1\_databases. |
| <a name="output_d1_databases"></a> [d1\_databases](#output\_d1\_databases) | Full cloudflare\_d1\_database objects, keyed by the same keys as var.d1\_databases. |
| <a name="output_deployment"></a> [deployment](#output\_deployment) | Full cloudflare\_workers\_deployment object, or null in the script deployment model. |
| <a name="output_enabled"></a> [enabled](#output\_enabled) | Whether this module created its resources. |
| <a name="output_hyperdrive_config_ids"></a> [hyperdrive\_config\_ids](#output\_hyperdrive\_config\_ids) | ID of each created Hyperdrive configuration, keyed by the same keys as var.hyperdrive\_configs. |
| <a name="output_hyperdrive_configs"></a> [hyperdrive\_configs](#output\_hyperdrive\_configs) | Full cloudflare\_hyperdrive\_config objects, keyed by the same keys as var.hyperdrive\_configs. Contains origin credentials. |
| <a name="output_kv_namespace_ids"></a> [kv\_namespace\_ids](#output\_kv\_namespace\_ids) | Namespace ID of each created KV namespace, keyed by the same keys as var.kv\_namespaces. |
| <a name="output_kv_namespaces"></a> [kv\_namespaces](#output\_kv\_namespaces) | Full cloudflare\_workers\_kv\_namespace objects, keyed by the same keys as var.kv\_namespaces. |
| <a name="output_kv_pairs"></a> [kv\_pairs](#output\_kv\_pairs) | Full cloudflare\_workers\_kv objects, keyed by the same keys as var.kv\_pairs. |
| <a name="output_pages_domains"></a> [pages\_domains](#output\_pages\_domains) | Full cloudflare\_pages\_domain objects, keyed by the same keys as var.pages\_domains. |
| <a name="output_pages_project_subdomains"></a> [pages\_project\_subdomains](#output\_pages\_project\_subdomains) | The pages.dev subdomain of each created Pages project. |
| <a name="output_pages_projects"></a> [pages\_projects](#output\_pages\_projects) | Full cloudflare\_pages\_project objects, keyed by the same keys as var.pages\_projects. |
| <a name="output_queue_consumers"></a> [queue\_consumers](#output\_queue\_consumers) | Full cloudflare\_queue\_consumer objects, keyed by the same keys as var.queues. |
| <a name="output_queue_ids"></a> [queue\_ids](#output\_queue\_ids) | Queue ID of each created queue, keyed by the same keys as var.queues. |
| <a name="output_queues"></a> [queues](#output\_queues) | Full cloudflare\_queue objects, keyed by the same keys as var.queues. |
| <a name="output_r2_bucket_names"></a> [r2\_bucket\_names](#output\_r2\_bucket\_names) | Name of each created R2 bucket, keyed by the same keys as var.r2\_buckets. |
| <a name="output_r2_buckets"></a> [r2\_buckets](#output\_r2\_buckets) | Full cloudflare\_r2\_bucket objects, keyed by the same keys as var.r2\_buckets. |
| <a name="output_r2_custom_domains"></a> [r2\_custom\_domains](#output\_r2\_custom\_domains) | Full cloudflare\_r2\_custom\_domain objects, keyed by "<bucket key>/<domain key>". |
| <a name="output_routes"></a> [routes](#output\_routes) | Full cloudflare\_workers\_route objects, keyed by the same keys as var.routes. |
| <a name="output_script"></a> [script](#output\_script) | Full cloudflare\_workers\_script object, or null in the versioned deployment model. Contains binding values. |
| <a name="output_script_id"></a> [script\_id](#output\_script\_id) | ID of the deployed Worker. |
| <a name="output_script_name"></a> [script\_name](#output\_script\_name) | Name of the deployed Worker, or null when script\_name was not set. |
| <a name="output_subdomain"></a> [subdomain](#output\_subdomain) | Full cloudflare\_workers\_script\_subdomain object, or null when workers\_dev was not set. |
| <a name="output_worker"></a> [worker](#output\_worker) | Full cloudflare\_worker object, or null in the script deployment model. |
| <a name="output_worker_version"></a> [worker\_version](#output\_worker\_version) | Full cloudflare\_worker\_version object, or null in the script deployment model. |
<!-- END_TF_DOCS -->

---

## License

Apache 2.0. See [LICENSE](LICENSE).

Maintained by [CloudDrove](https://clouddrove.com) and [Cloud Wizz](https://github.com/cloud-wizz).
