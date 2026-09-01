# Plan only. Runs on every pull request, including forks, with no credentials.

mock_provider "cloudflare" {
}

variables {
  account_id = "00000000000000000000000000000000"
  zone_id    = "00000000000000000000000000000000"
}

run "creates_nothing_when_disabled" {
  command = plan

  variables {
    enabled     = false
    script_name = "disabled-worker"
    content     = "export default { fetch: () => new Response('x') };"

    kv_namespaces = {
      cache = { title = "disabled-cache", binding = "CACHE" }
    }
  }

  assert {
    condition     = output.enabled == false
    error_message = "Module reported enabled while var.enabled was false."
  }

  assert {
    condition     = output.script_name == null
    error_message = "Module produced a Worker while var.enabled was false."
  }

  assert {
    condition     = length(output.kv_namespaces) == 0
    error_message = "Module produced KV namespaces while var.enabled was false."
  }
}

run "enabled_by_default" {
  command = plan

  assert {
    condition     = output.enabled == true
    error_message = "Module should be enabled by default."
  }
}

run "no_worker_without_script_name" {
  command = plan

  variables {
    kv_namespaces = {
      shared = { title = "shared-cache" }
    }
  }

  assert {
    condition     = output.script_name == null
    error_message = "Module produced a Worker without a script_name."
  }

  assert {
    condition     = length(output.kv_namespaces) == 1
    error_message = "Module should still create storage when no Worker is requested."
  }
}

run "worker_with_derived_bindings" {
  command = plan

  variables {
    script_name        = "test-worker"
    compatibility_date = "2025-06-01"
    content            = "export default { fetch: () => new Response('x') };"

    kv_namespaces = {
      cache = { title = "test-cache", binding = "CACHE" }
      plain = { title = "test-plain" }
    }

    d1_databases = {
      app = { name = "test-app", binding = "DB" }
    }

    queues = {
      jobs = {
        queue_name = "test-jobs"
        binding    = "JOBS"
        consumer   = { type = "worker" }
      }
    }

    r2_buckets = {
      uploads = { name = "test-uploads", binding = "UPLOADS" }
    }

    hyperdrive_configs = {
      primary = {
        name    = "test-primary"
        binding = "HYPERDRIVE"
        origin = {
          database = "appdb"
          scheme   = "postgres"
          user     = "app"
          password = "not-a-real-password"
          host     = "db.example.com"
          port     = 5432
        }
      }
    }

    bindings = {
      ENVIRONMENT = { type = "plain_text", text = "test" }
    }

    routes = {
      api = { pattern = "example.com/api/*" }
    }

    custom_domains = {
      api = { hostname = "worker.example.com" }
    }

    cron_schedules = ["*/5 * * * *"]

    workers_dev = { enabled = true }
  }

  assert {
    condition     = output.script_name == "test-worker"
    error_message = "Module did not report the Worker name it was asked to deploy."
  }

  assert {
    condition = alltrue([
      for name in ["CACHE", "DB", "JOBS", "UPLOADS", "HYPERDRIVE", "ENVIRONMENT"] :
      contains(keys(nonsensitive(output.bindings)), name)
    ])
    error_message = "Module did not derive one binding per storage entry that named a binding."
  }

  assert {
    condition     = length(nonsensitive(output.bindings)) == 6
    error_message = "Storage entries without a binding name should not produce a binding."
  }

  assert {
    condition     = nonsensitive(output.bindings)["CACHE"].type == "kv_namespace"
    error_message = "KV namespaces should produce a kv_namespace binding."
  }

  assert {
    condition     = nonsensitive(output.bindings)["DB"].type == "d1"
    error_message = "D1 databases should produce a d1 binding."
  }

  assert {
    condition     = nonsensitive(output.bindings)["JOBS"].queue_name == "test-jobs"
    error_message = "Queue bindings should carry the queue name."
  }

  assert {
    condition     = nonsensitive(output.bindings)["UPLOADS"].bucket_name == "test-uploads"
    error_message = "R2 bindings should carry the bucket name."
  }

  assert {
    condition     = length(output.routes) == 1 && length(output.custom_domains) == 1
    error_message = "Routes and custom domains were not created."
  }

  assert {
    condition     = length(output.cron_triggers) == 1
    error_message = "Cron schedules did not produce a cron trigger."
  }

  assert {
    condition     = length(output.queue_consumers) == 1
    error_message = "An inline queue consumer did not produce a cloudflare_queue_consumer."
  }
}

run "versioned_deployment_model" {
  command = plan

  variables {
    script_name        = "versioned-worker"
    deployment_model   = "versioned"
    compatibility_date = "2025-06-01"
    main_module        = "worker.js"
    content            = "export default { fetch: () => new Response('x') };"
    worker_tags        = ["platform"]
    version_message    = "initial rollout"

    workers_dev = { enabled = true, previews_enabled = true }
  }

  assert {
    condition     = output.script == null
    error_message = "The versioned model should not create a cloudflare_workers_script."
  }

  assert {
    condition     = output.worker != null
    error_message = "The versioned model should create a cloudflare_worker."
  }

  assert {
    condition     = output.deployment != null
    error_message = "The versioned model should create a cloudflare_workers_deployment."
  }
}

run "pages_project" {
  command = plan

  variables {
    pages_projects = {
      site = {
        name              = "test-site"
        production_branch = "main"

        production = {
          compatibility_date = "2025-06-01"
          env_vars = {
            NODE_VERSION = { type = "plain_text", value = "20" }
          }
        }
      }
    }

    pages_domains = {
      www = { name = "www.example.com", project_key = "site" }
    }
  }

  assert {
    condition     = length(output.pages_domains) == 1
    error_message = "Pages domain was not created."
  }
}
