# Binding wiring, the non obvious part of deploying a Worker.
#
# The left hand example lets the root module create the storage and derive the
# bindings. The right hand example uses the submodules directly, which is what
# you need when the storage is owned by a different Terraform configuration or
# a different team.

provider "cloudflare" {
  # Reads CLOUDFLARE_API_TOKEN from the environment.
}

# -----------------------------------------------------------------------------
# 1. Storage created and bound by the root module.
#
#    Each storage entry names the JavaScript variable the Worker will see. The
#    module fills in the namespace ID, database UUID, bucket name or config ID
#    once the resource exists, so nothing has to be copied by hand.
# -----------------------------------------------------------------------------

module "derived" {
  source = "../../"

  account_id         = var.account_id
  script_name        = "bindings-derived"
  compatibility_date = "2025-06-01"

  content = <<-JS
    export default {
      async fetch(request, env) {
        const cached = await env.CACHE.get("key");
        const { results } = await env.DB.prepare("select 1").all();
        await env.JOBS.send({ cached, results });
        return new Response("ok");
      },
    };
  JS

  kv_namespaces = {
    cache = { title = "bindings-cache", binding = "CACHE" }
  }

  d1_databases = {
    app = { name = "bindings-app", binding = "DB" }
  }

  queues = {
    jobs = { queue_name = "bindings-jobs", binding = "JOBS" }
  }

  r2_buckets = {
    uploads = { name = "bindings-uploads", binding = "UPLOADS" }
  }
}

# -----------------------------------------------------------------------------
# 2. Storage created separately, then bound by hand.
#
#    modules/script takes the same binding map. When you build it yourself, the
#    key is the JavaScript variable name and `type` decides which other field
#    the Workers API reads: namespace_id for KV, database_id for D1, queue_name
#    for a queue producer, bucket_name for R2, id for Hyperdrive.
# -----------------------------------------------------------------------------

module "storage" {
  source = "../../modules/kv"

  account_id = var.account_id

  namespaces = {
    shared = { title = "bindings-shared" }
  }
}

module "explicit" {
  source = "../../modules/script"

  account_id         = var.account_id
  script_name        = "bindings-explicit"
  compatibility_date = "2025-06-01"
  main_module        = "worker.js"

  content = <<-JS
    export default {
      async fetch(request, env) {
        return new Response(await env.SHARED.get("key"));
      },
    };
  JS

  bindings = {
    SHARED = {
      type         = "kv_namespace"
      namespace_id = module.storage.namespace_ids["shared"]
    }
    UPSTREAM = {
      type    = "service"
      service = "bindings-derived"
    }
    RELEASE = {
      type = "plain_text"
      text = "2025.06.1"
    }
  }
}

# -----------------------------------------------------------------------------
# 3. Routes and cron triggers pointed at a Worker built elsewhere.
# -----------------------------------------------------------------------------

module "triggers" {
  source = "../../modules/route"

  account_id = var.account_id
  zone_id    = var.zone_id

  routes = {
    api = {
      pattern = "example.com/api/*"
      script  = module.explicit.script_name
    }
  }
}

module "schedule" {
  source = "../../modules/cron"

  account_id = var.account_id

  triggers = {
    nightly = {
      script_name = module.explicit.script_name
      schedules   = ["0 3 * * *"]
    }
  }
}
