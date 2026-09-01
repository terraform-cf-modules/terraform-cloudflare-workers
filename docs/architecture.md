# Architecture

This module deploys a Cloudflare Worker and the things a Worker needs to be useful: somewhere for traffic to
arrive from, a schedule to wake it, and storage to read and write. Pages is included because Pages Functions run
on the same runtime and bind to the same storage products.

## Resource map

| Terraform resource | Cloudflare object | Created by |
|--------------------|-------------------|------------|
| `cloudflare_workers_script` | Worker script upload | `modules/script`, `deployment_model = "script"` |
| `cloudflare_workers_script_subdomain` | workers.dev subdomain toggle | `modules/script`, `deployment_model = "script"` |
| `cloudflare_worker` | Worker container object | `modules/script`, `deployment_model = "versioned"` |
| `cloudflare_worker_version` | immutable version of a Worker | `modules/script`, `deployment_model = "versioned"` |
| `cloudflare_workers_deployment` | which version serves traffic | `modules/script`, `deployment_model = "versioned"` |
| `cloudflare_workers_route` | URL pattern on a zone | `modules/route` |
| `cloudflare_workers_custom_domain` | hostname routed to a Worker | `modules/route` |
| `cloudflare_workers_cron_trigger` | schedule list for a script | `modules/cron` |
| `cloudflare_workers_kv_namespace` | KV namespace | `modules/kv` |
| `cloudflare_workers_kv` | key/value pair inside a namespace | `modules/kv` |
| `cloudflare_d1_database` | D1 database | `modules/d1` |
| `cloudflare_queue` | queue | `modules/queue` |
| `cloudflare_queue_consumer` | worker or pull consumer of a queue | `modules/queue` |
| `cloudflare_r2_bucket` | R2 bucket | `modules/r2` |
| `cloudflare_r2_bucket_cors` | CORS rule list for a bucket | `modules/r2` |
| `cloudflare_r2_bucket_lifecycle` | lifecycle rule list for a bucket | `modules/r2` |
| `cloudflare_r2_bucket_lock` | object lock rule list for a bucket | `modules/r2` |
| `cloudflare_r2_bucket_event_notification` | bucket events published to a queue | `modules/r2` |
| `cloudflare_r2_custom_domain` | public hostname for a bucket | `modules/r2` |
| `cloudflare_hyperdrive_config` | connection pool in front of an SQL origin | `modules/hyperdrive` |
| `cloudflare_pages_project` | Pages project | `modules/pages` |
| `cloudflare_pages_domain` | custom domain on a Pages project | `modules/pages` |

Everything above was checked against the `cloudflare/cloudflare` v5.24 provider schema. Every resource named in
the module brief exists under that name; nothing had to be substituted.

## Scope

Account scoped. `account_id` anchors the Worker, all five storage products and Pages.

Zone scoped for routing only. `cloudflare_workers_route` requires a `zone_id`, and
`cloudflare_workers_custom_domain` and `cloudflare_r2_custom_domain` need either `zone_id` or `zone_name` to place
the hostname. The root module's `zone_id` is the default for those; individual routes and domains can override it,
which is how one Worker serves patterns across several zones.

## Choosing between `cloudflare_workers_script` and the `cloudflare_worker` triple

The v5 provider ships two overlapping ways to deploy a Worker.

**`cloudflare_workers_script`** is the single resource form. One `terraform apply` uploads code, bindings, limits,
observability and placement in one call, and that upload immediately becomes what serves traffic. It maps to the
long standing `PUT /accounts/:id/workers/scripts/:name` endpoint.

**`cloudflare_worker` + `cloudflare_worker_version` + `cloudflare_workers_deployment`** splits the same thing three
ways, mirroring how the Workers API actually models a Worker today:

- `cloudflare_worker` is the container. It holds the name, tags, logpush setting, observability configuration,
  tail consumers and the workers.dev subdomain. It has an immutable ID that survives code changes.
- `cloudflare_worker_version` is an immutable upload: modules, bindings, compatibility date and flags, limits,
  placement and migrations. Changing code creates a new version rather than replacing the old one.
- `cloudflare_workers_deployment` decides which versions serve traffic and in what proportion, using the
  `percentage` strategy. This is what gradual deployments and instant rollbacks are built on.

**This module defaults to `cloudflare_workers_script`,** and exposes the triple behind
`deployment_model = "versioned"`.

The reasoning:

1. The provider documentation for `cloudflare_workers_script` recommends the triple "for more direct control over
   Workers resources", and describes it as **beta**. A module published to the registry with a version constraint
   should not put a beta surface on the default path, because a breaking change there becomes a breaking change
   for every caller.
2. Neither resource is marked deprecated in the v5.24 schema. `cloudflare_workers_script` is not on its way out;
   it is the surface most existing configurations use, and it is the one the provider's own acceptance surface has
   the longest history with.
3. The single resource model is genuinely simpler for the common case. Most Workers do not need staged rollouts,
   and with the triple a code change produces three resource updates instead of one.
4. Splitting a Worker into three resources changes the state layout. Callers who start on the triple cannot move
   back without state surgery, so the default should be the one that is easy to leave.

Switch to `versioned` when you want a version uploaded before it takes traffic, want to roll back by pointing the
deployment at an earlier version, or want gradual rollout percentages. The module keeps the same inputs for both:
`bindings`, `compatibility_date`, `limits`, `placement_mode`, `migrations`, `assets` and `workers_dev` all work
either way.

Two differences are unavoidable:

- `cloudflare_worker_version` has no inline `content`. Code is uploaded as named modules. When you pass `content`
  with `main_module`, `modules/script` base64 encodes it into a module named after `main_module`, so the same
  inputs work for both models.
- `cloudflare_worker.tail_consumers` takes `{ name }`, while `cloudflare_workers_script.tail_consumers` takes
  `{ service, environment, namespace }`. The module takes the richer form and drops the extra fields for the
  versioned model.

## How bindings are derived

`bindings` on `cloudflare_workers_script` is a list of objects with a `name` and a `type`, and roughly forty other
optional fields of which each type uses one or two. The schema summary reports the attribute as a null type
because it is a nested list type rather than a primitive, so the real shape has to be read out of the provider
schema directly. `modules/script` types the whole thing, so a typo in a field name is caught at plan.

Callers give a map keyed by binding name rather than a list, for the usual reason: a list reorder rewrites every
element's state address. `modules/script` converts the map to the list the provider wants, injecting the key as
`name`.

The root module goes one step further. Each entry in `kv_namespaces`, `d1_databases`, `queues`, `r2_buckets` and
`hyperdrive_configs` can carry a `binding` field. `locals.tf` turns each of those into the correct binding object,
pulling the identifier out of the resource that was just created:

| Storage | Binding type | Field the API reads | Known at plan? |
|---------|--------------|---------------------|----------------|
| KV namespace | `kv_namespace` | `namespace_id` | no, computed |
| D1 database | `d1` | `database_id` | no, computed |
| Hyperdrive config | `hyperdrive` | `id` | no, computed |
| Queue | `queue` | `queue_name` | yes, from input |
| R2 bucket | `r2_bucket` | `bucket_name`, `jurisdiction` | yes, from input |

Those derived bindings are merged with the caller's own `bindings` map. A name appearing in both is rejected by a
cross variable `validation` block on `var.bindings` rather than being silently overwritten by `merge()`.

## Ordering and dependencies

There is no `depends_on` anywhere in this module. Everything orders itself through references:

- The Worker depends on the storage because its bindings read `module.kv.namespace_ids`,
  `module.d1.database_ids`, `module.queue.queue_names`, `module.r2.bucket_names` and
  `module.hyperdrive.config_ids`.
- Routes, custom domains and cron triggers depend on the Worker because they read `module.script.script_name`,
  which is sourced from the resource rather than from `var.script_name`. The value is identical; the reference is
  what creates the edge. Using `var.script_name` directly would let Terraform create a route before the script
  exists, and the API rejects that.
- Queue consumers depend on the Worker for the same reason, and on the queue through
  `cloudflare_queue.this[...].queue_id`. There is no cycle: `cloudflare_queue` and `cloudflare_queue_consumer` are
  separate nodes, and only the consumer references the Worker.
- R2 sub resources read `cloudflare_r2_bucket.this[...].name` and `.jurisdiction` rather than the input values, so
  they cannot be created before the bucket and cannot disagree with it about the jurisdiction.

## Known provider quirks

**`cloudflare_workers_script` requires one of `content`, `content_file` or `assets`.** The provider enforces this
at plan time, not through a required attribute, so a Worker with only bindings and no code fails with
"At least one of these attributes must be configured".

**R2 sub resources address the bucket by a triple, not an ID.** `account_id`, `bucket_name` and `jurisdiction`
appear on every CORS, lifecycle, lock, event notification and custom domain resource. Getting the jurisdiction
wrong on a sub resource points it at a bucket that does not exist. This module always reads the jurisdiction back
off the created bucket rather than passing the input value through twice.

**`cloudflare_workers_cron_trigger` owns the whole schedule list for a script.** It is not one resource per
schedule. Two resources for the same `script_name` fight over the same API object, so `modules/cron` validates
that each script name appears in only one entry.

**Hyperdrive's `origin.password` is write only.** The API never returns it, so Terraform cannot detect drift on
it, and the value sits in state. The variable is deliberately not marked `sensitive`, because Terraform refuses a
sensitive value as a `for_each` argument; the provider schema already marks the resource attribute sensitive, so
plan output redacts it.

**Deprecated attributes avoided.** In v5.24 the schema marks `cloudflare_worker_version.usage_model`,
`cloudflare_workers_custom_domain.environment`, `cloudflare_workers_script.assets.config.serve_directly`,
`cloudflare_pages_project.deployment_configs.*.usage_model` and
`cloudflare_pages_project.source.config.deployments_enabled` as deprecated. None of them is exposed as an input,
so a plan through this module produces no deprecation warnings from configuration.

**`usage_model` is not deprecated on `cloudflare_workers_script`.** It is on `cloudflare_worker_version`. The
module therefore passes it only in the `script` model.

**Pages Functions bind differently from Workers.** `cloudflare_pages_project.deployment_configs.{preview,production}`
takes one map per binding kind (`kv_namespaces`, `d1_databases`, `r2_buckets`, `services`, and so on) rather than
one list with a `type` field. `modules/pages/locals.tf` translates a flat, readable input into that shape.

**`cloudflare_workers_route.script` is optional.** Leaving it null creates a route that explicitly bypasses
Workers for that pattern, which is occasionally what you want in front of a broader route.
