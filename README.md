<!-- This file was automatically generated from `README.yaml`. Make all changes to `README.yaml` and run `make readme` to rebuild this file. -->
<p align="center">
  <img width="1000" alt="CloudDrove Banner" src="https://clouddrove.s3.ca-central-1.amazonaws.com/img/clouddrove-github-cover.png" />
</p>
<h1 align="center">
    Cloudflare Workers
</h1>

<p align="center" style="font-size: 1.2rem;">
    With our comprehensive DevOps toolkit, streamline operations, automate workflows, enhance collaboration and deploy with confidence.
</p>

<p align="center">

<a href="https://www.terraform.io">
  <img src="https://img.shields.io/badge/Terraform-v1.12.0-green" alt="Terraform">
</a>
<a href="LICENSE">
  <img src="https://img.shields.io/badge/License-APACHE-blue.svg" alt="Licence">
</a>
<a href="CHANGELOG.md">
  <img src="https://img.shields.io/badge/Changelog-blue" alt="Changelog">
</a>
<a href="https://github.com/terraform-cf-modules/terraform-cloudflare-workers/actions/workflows/tf-checks.yml">
  <img src="https://github.com/terraform-cf-modules/terraform-cloudflare-workers/actions/workflows/tf-checks.yml/badge.svg" alt="tf-checks">
</a>
<a href="https://github.com/terraform-cf-modules/terraform-cloudflare-workers/actions/workflows/tflint.yml">
  <img src="https://github.com/terraform-cf-modules/terraform-cloudflare-workers/actions/workflows/tflint.yml/badge.svg" alt="tf-lint">
</a>
<a href="https://github.com/terraform-cf-modules/terraform-cloudflare-workers/actions/workflows/checkov.yml">
  <img src="https://github.com/terraform-cf-modules/terraform-cloudflare-workers/actions/workflows/checkov.yml/badge.svg" alt="checkov">
</a>
<a href="https://github.com/terraform-cf-modules/terraform-cloudflare-workers/actions/workflows/test.yml">
  <img src="https://github.com/terraform-cf-modules/terraform-cloudflare-workers/actions/workflows/test.yml/badge.svg" alt="test">
</a>

</p>
<hr>


Deploys a Cloudflare Worker together with everything that has to exist around it: the routes and custom domains
that send traffic to it, the cron triggers that wake it on a schedule, and the KV namespaces, D1 databases,
Queues, R2 buckets and Hyperdrive configurations it reads and writes. Pages projects are covered too, because
Pages Functions run on the same runtime and bind to the same storage products.

The binding wiring is the reason the module exists.
Binding a Worker to a KV namespace, a D1 database, an R2 bucket and a queue by hand means copying namespace IDs
and database UUIDs out of one resource into a list of untyped binding objects on another, in a different shape
for every binding type. Here the JavaScript variable name is declared once, next to the storage that backs it,
and the module builds the binding list.

| Binding source | How you declare it |
|----------------|--------------------|
| KV namespace this module creates | `kv_namespaces = { cache = { title = "...", binding = "CACHE" } }` |
| D1 database this module creates | `d1_databases = { app = { name = "...", binding = "DB" } }` |
| Queue this module creates | `queues = { jobs = { queue_name = "...", binding = "JOBS" } }` |
| R2 bucket this module creates | `r2_buckets = { uploads = { name = "...", binding = "UPLOADS" } }` |
| Hyperdrive config this module creates | `hyperdrive_configs = { db = { ..., binding = "HYPERDRIVE" } }` |
| Anything else | `bindings = { NAME = { type = "...", ... } }` |

Anything the module did not create goes into `bindings` in the provider's own shape, keyed by the name the
Worker sees on `env`: `{ type = "plain_text", text = "production" }`, `{ type = "service", service =
"other-worker" }`, `{ type = "kv_namespace", namespace_id = var.existing_namespace_id }` and so on. A key in
`bindings` that collides with a name derived from the storage maps is rejected at plan time rather than
silently overwriting one of the two. Values for `secret_text`, `key_base64` and `key_jwk` bindings land in
Terraform state in plain text, so prefer a `secrets_store_secret` binding (`store_id`, `secret_name`), or set
the secret outside Terraform and add `keep_bindings = ["secret_text"]` so uploads do not wipe it.

Two deployment models are available, selected with `deployment_model`.

| `deployment_model` | Resources | Why you would pick it |
|--------------------|-----------|-----------------------|
| `script` (default) | `cloudflare_workers_script`, `cloudflare_workers_script_subdomain` | Generally available in the provider. Each apply replaces the live code in one step. |
| `versioned` | `cloudflare_worker`, `cloudflare_worker_version`, `cloudflare_workers_deployment` | Mirrors Cloudflare's versions and deployments API: upload a version, then roll it out. All three resources are still marked beta. |

`script` is the default deliberately. It is the surface Cloudflare supports without a beta flag, and it is what
most Workers need. Switch to `deployment_model = "versioned"` when you want the version history and staged
rollout that the deployments API gives you, and accept that the resources may change shape while they are in
beta. [docs/architecture.md](docs/architecture.md) has the full resource map and the reasoning behind the split.

This module targets Cloudflare provider v5. Cloudflare rewrote the provider from its OpenAPI spec in v5.0.0 and
renamed most resources, so verify resource names and attributes against the current provider documentation
rather than from memory or from older examples. The API token you apply with needs `Workers Scripts Read` and
`Workers Scripts Write`, plus `Workers KV Storage`, `D1`, `Queues`, `Workers R2 Storage`, `Hyperdrive` and
`Pages` permissions for whichever parts of the module you use.


## Prerequisites and Providers

This table contains both Prerequisites and Providers:

| Description | Name | Version |
|-------------|------|---------|
| Prerequisite | Terraform | >= 1.12.0 |
| Prerequisite | OpenTofu | >= 1.12.0 |
| Provider | cloudflare | ~> 5.24 |

---


## 🧩 Submodules

Each submodule is separately addressable with the double slash source syntax, so you can take only the piece you need instead of the whole root module.

| Submodule | Source | Description |
|-----------|--------|-------------|
| `script` | `terraform-cf-modules/workers/cloudflare//modules/script` | Uploads the Worker: code, bindings, compatibility flags, migrations, static assets, limits and observability. `deployment_model` selects the script or the versioned resource set. |
| `route` | `terraform-cf-modules/workers/cloudflare//modules/route` | The two ways traffic reaches a Worker from a zone you own: `cloudflare_workers_route` URL patterns and `cloudflare_workers_custom_domain` hostnames with their certificates. |
| `cron` | `terraform-cf-modules/workers/cloudflare//modules/cron` | Cron triggers for a Worker's `scheduled` handler. One entry owns a script's whole schedule list, and two entries naming the same script are rejected instead of fighting over the same API object. |
| `kv` | `terraform-cf-modules/workers/cloudflare//modules/kv` | Workers KV namespaces and the key/value pairs written into them. |
| `d1` | `terraform-cf-modules/workers/cloudflare//modules/d1` | D1 serverless SQL databases, with location hint, jurisdiction and read replication settings. |
| `queue` | `terraform-cf-modules/workers/cloudflare//modules/queue` | Cloudflare Queues and their consumers: `worker` for push delivery to a `queue` handler, `http_pull` for a client that pulls batches over HTTP. |
| `r2` | `terraform-cf-modules/workers/cloudflare//modules/r2` | R2 buckets and everything hanging off them: CORS, lifecycle, object lock, event notifications and public custom domains, all declared inside the bucket entry. |
| `hyperdrive` | `terraform-cf-modules/workers/cloudflare//modules/hyperdrive` | Hyperdrive connection pools in front of an existing PostgreSQL or MySQL origin, so a Worker skips the connection setup cost on every request. |
| `pages` | `terraform-cf-modules/workers/cloudflare//modules/pages` | Pages projects and their custom domains. Pages Functions take bindings as one map per kind rather than one typed list, and this submodule translates the flat form. |

Reach for a submodule when the pieces are owned by different configurations, for example storage in a platform
repository and the Worker in a team one. The root module composes all of them for the common case.

---


## 🚀 Usage

### Root module

One Worker, its storage, its routes and its schedule. Each storage entry that sets `binding` becomes a Worker
binding automatically, so no IDs are copied by hand.

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
    cache = { title = "api-cache", binding = "CACHE" }
  }

  d1_databases = {
    app = { name = "api-app", binding = "DB" }
  }

  r2_buckets = {
    uploads = { name = "api-uploads", binding = "UPLOADS" }
  }

  queues = {
    jobs = {
      queue_name = "api-jobs"
      binding    = "JOBS"
      consumer   = { type = "worker" }
    }
  }

  bindings = {
    ENVIRONMENT = { type = "plain_text", text = "production" }
  }

  routes = {
    api = { pattern = "example.com/api/*" }
  }

  cron_schedules = ["*/15 * * * *"]
}
```

### Submodules used standalone

Storage created in one configuration, the Worker in another. `modules/script` takes bindings in the provider's
own shape, so the namespace ID comes from the `kv` submodule's output.

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

  workers_dev = { enabled = true }
}
```

### Wrapper for many Workers

`wrappers/` applies the root module once per entry in `items`, with `defaults` merged underneath.

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


## 📦 Examples

> ⚠️ **Important:** Avoid using the `main` branch directly, as it may include unstable changes. Always use stable [release versions](https://github.com/terraform-cf-modules/terraform-cloudflare-workers/releases).

Explore real-world usage scenarios and implementation patterns in the [`examples/`](./examples/) directory.

---


## 📥 Inputs and Outputs

Detailed input variables and output values are documented for easier integration and day-to-day usage.

📘 [View full documentation](docs/io.md)

---


## 📝 Changelog

Track module updates, improvements, and breaking changes across versions.

📌 [View Changelog](CHANGELOG.md)

---


## ✨ Contributors

Big thanks to our contributors for elevating our project with their dedication and expertise!

<div align="center">
  <a href="https://github.com/terraform-cf-modules/terraform-cloudflare-workers/graphs/contributors" title="Contributors">
    <img src="https://contrib.rocks/image?repo=terraform-cf-modules/terraform-cloudflare-workers" />
  </a>
</div>

All contributors must follow the [Conventional Commits](https://www.conventionalcommits.org) specification for commit messages.

---


## 🚀 Our Accomplishment

We maintain Terraform modules across AWS, Azure, Google Cloud, DigitalOcean, Hetzner Cloud and Cloudflare 🙌.

- [**Terraform Module Registry**](https://registry.terraform.io/namespaces/terraform-cf-modules): Discover our Cloudflare modules here.
- [**Full module catalog**](https://github.com/clouddrove/toc): Every CloudDrove module and submodule, across every cloud.

---

## Notes

- Do not use the `main` branch for production deployments.
- Always reference a stable version using Git tags or official releases.
- Using tagged versions ensures consistency, stability, and reproducible deployments.

---

## Feedback

Report issues or request features on [GitHub](https://github.com/terraform-cf-modules/terraform-cloudflare-workers/issues), or write to [business@clouddrove.com](mailto:business@clouddrove.com).

## About us

At [CloudDrove](https://clouddrove.com), we build reliable, secure and cost efficient cloud native solutions. Join our [Slack community](https://www.launchpass.com/devops-talks).
