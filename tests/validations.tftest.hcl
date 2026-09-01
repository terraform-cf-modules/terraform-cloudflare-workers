# Input validation. Plan only, no credentials.
#
# Root module validations come first, then one run per submodule using the
# `module` block so each submodule's own validation blocks are exercised.

mock_provider "cloudflare" {
  override_during = plan
}

variables {
  account_id = "00000000000000000000000000000000"
}

# -----------------------------------------------------------------------------
# Root module
# -----------------------------------------------------------------------------

run "rejects_malformed_account_id" {
  command = plan

  variables {
    account_id = "not-a-valid-account-id"
  }

  expect_failures = [var.account_id]
}

run "rejects_malformed_zone_id" {
  command = plan

  variables {
    zone_id = "TOO-SHORT"
  }

  expect_failures = [var.zone_id]
}

run "rejects_malformed_script_name" {
  command = plan

  variables {
    script_name = "Not A Valid Worker Name"
  }

  expect_failures = [var.script_name]
}

run "rejects_unknown_deployment_model" {
  command = plan

  variables {
    deployment_model = "canary"
  }

  expect_failures = [var.deployment_model]
}

run "rejects_unknown_usage_model" {
  command = plan

  variables {
    usage_model = "gigantic"
  }

  expect_failures = [var.usage_model]
}

run "rejects_unknown_placement_mode" {
  command = plan

  variables {
    placement_mode = "nearby"
  }

  expect_failures = [var.placement_mode]
}

run "rejects_binding_key_that_is_not_an_identifier" {
  command = plan

  variables {
    bindings = {
      "my-cache" = { type = "kv_namespace", namespace_id = "00000000000000000000000000000000" }
    }
  }

  expect_failures = [var.bindings]
}

run "rejects_binding_name_colliding_with_derived_binding" {
  command = plan

  variables {
    kv_namespaces = {
      cache = { title = "cache", binding = "CACHE" }
    }
    bindings = {
      CACHE = { type = "plain_text", text = "collision" }
    }
  }

  expect_failures = [var.bindings]
}

run "rejects_unknown_queue_consumer_type" {
  command = plan

  variables {
    queues = {
      jobs = {
        queue_name = "jobs"
        consumer   = { type = "pull" }
      }
    }
  }

  expect_failures = [var.queues]
}

# -----------------------------------------------------------------------------
# modules/script
# -----------------------------------------------------------------------------

run "script_rejects_unknown_binding_type" {
  command = plan

  module {
    source = "./modules/script"
  }

  variables {
    script_name = "validation-worker"
    content     = "export default { fetch: () => new Response('x') };"
    bindings = {
      THING = { type = "sqlite" }
    }
  }

  expect_failures = [var.bindings]
}

run "script_rejects_kv_binding_without_namespace_id" {
  command = plan

  module {
    source = "./modules/script"
  }

  variables {
    script_name = "validation-worker"
    content     = "export default { fetch: () => new Response('x') };"
    bindings = {
      CACHE = { type = "kv_namespace" }
    }
  }

  expect_failures = [var.bindings]
}

run "script_rejects_ratelimit_binding_without_simple" {
  command = plan

  module {
    source = "./modules/script"
  }

  variables {
    script_name = "validation-worker"
    content     = "export default { fetch: () => new Response('x') };"
    bindings = {
      THROTTLE = { type = "ratelimit" }
    }
  }

  expect_failures = [var.bindings]
}

run "script_rejects_malformed_compatibility_date" {
  command = plan

  module {
    source = "./modules/script"
  }

  variables {
    script_name        = "validation-worker"
    content            = "export default { fetch: () => new Response('x') };"
    compatibility_date = "June 2025"
  }

  expect_failures = [var.compatibility_date]
}

run "script_rejects_module_with_two_content_sources" {
  command = plan

  module {
    source = "./modules/script"
  }

  variables {
    script_name = "validation-worker"
    content     = "export default { fetch: () => new Response('x') };"
    modules = {
      "worker.js" = {
        content_type   = "application/javascript+module"
        content_file   = "./worker.js"
        content_base64 = "ZXhwb3J0IGRlZmF1bHQge30="
      }
    }
  }

  expect_failures = [var.modules]
}

# -----------------------------------------------------------------------------
# modules/route
# -----------------------------------------------------------------------------

run "route_rejects_pattern_with_scheme" {
  command = plan

  module {
    source = "./modules/route"
  }

  variables {
    zone_id = "00000000000000000000000000000000"
    routes = {
      api = { pattern = "https://example.com/api/*" }
    }
  }

  expect_failures = [var.routes]
}

run "route_rejects_hostname_that_is_not_a_hostname" {
  command = plan

  module {
    source = "./modules/route"
  }

  variables {
    zone_id = "00000000000000000000000000000000"
    custom_domains = {
      api = { hostname = "https://api.example.com/", service = "worker" }
    }
  }

  expect_failures = [var.custom_domains]
}

# -----------------------------------------------------------------------------
# modules/cron
# -----------------------------------------------------------------------------

run "cron_rejects_malformed_schedule" {
  command = plan

  module {
    source = "./modules/cron"
  }

  variables {
    triggers = {
      nightly = { script_name = "worker", schedules = ["every night"] }
    }
  }

  expect_failures = [var.triggers]
}

run "cron_rejects_duplicate_script_name" {
  command = plan

  module {
    source = "./modules/cron"
  }

  variables {
    triggers = {
      a = { script_name = "worker", schedules = ["0 1 * * *"] }
      b = { script_name = "worker", schedules = ["0 2 * * *"] }
    }
  }

  expect_failures = [var.triggers]
}

# -----------------------------------------------------------------------------
# modules/kv
# -----------------------------------------------------------------------------

run "kv_rejects_pair_without_a_namespace" {
  command = plan

  module {
    source = "./modules/kv"
  }

  variables {
    pairs = {
      greeting = { key_name = "greeting", value = "hello" }
    }
  }

  expect_failures = [var.pairs]
}

run "kv_rejects_pair_pointing_at_an_unknown_namespace_key" {
  command = plan

  module {
    source = "./modules/kv"
  }

  variables {
    namespaces = {
      cache = { title = "cache" }
    }
    pairs = {
      greeting = { key_name = "greeting", value = "hello", namespace_key = "missing" }
    }
  }

  expect_failures = [var.pairs]
}

# -----------------------------------------------------------------------------
# modules/d1
# -----------------------------------------------------------------------------

run "d1_rejects_unknown_location_hint" {
  command = plan

  module {
    source = "./modules/d1"
  }

  variables {
    databases = {
      app = { name = "app", primary_location_hint = "mars" }
    }
  }

  expect_failures = [var.databases]
}

run "d1_rejects_unknown_read_replication_mode" {
  command = plan

  module {
    source = "./modules/d1"
  }

  variables {
    databases = {
      app = { name = "app", read_replication_mode = "sometimes" }
    }
  }

  expect_failures = [var.databases]
}

# -----------------------------------------------------------------------------
# modules/queue
# -----------------------------------------------------------------------------

run "queue_rejects_out_of_range_retention_period" {
  command = plan

  module {
    source = "./modules/queue"
  }

  variables {
    queues = {
      jobs = { queue_name = "jobs", message_retention_period = 10 }
    }
  }

  expect_failures = [var.queues]
}

run "queue_rejects_worker_consumer_without_script_name" {
  command = plan

  module {
    source = "./modules/queue"
  }

  variables {
    queues = {
      jobs = { queue_name = "jobs" }
    }
    consumers = {
      jobs = { type = "worker", queue_key = "jobs" }
    }
  }

  expect_failures = [var.consumers]
}

# -----------------------------------------------------------------------------
# modules/r2
# -----------------------------------------------------------------------------

run "r2_rejects_unknown_bucket_location" {
  command = plan

  module {
    source = "./modules/r2"
  }

  variables {
    buckets = {
      uploads = { name = "uploads", location = "atlantis" }
    }
  }

  expect_failures = [var.buckets]
}

run "r2_rejects_age_lock_rule_without_max_age" {
  command = plan

  module {
    source = "./modules/r2"
  }

  variables {
    buckets = {
      uploads = {
        name = "uploads"
        lock_rules = {
          audit = { condition_type = "Age" }
        }
      }
    }
  }

  expect_failures = [var.buckets]
}

run "r2_rejects_lifecycle_rule_with_two_delete_conditions" {
  command = plan

  module {
    source = "./modules/r2"
  }

  variables {
    buckets = {
      uploads = {
        name = "uploads"
        lifecycle_rules = {
          expire = {
            delete_objects_after_days = 30
            delete_objects_on_date    = "2030-01-01T00:00:00Z"
          }
        }
      }
    }
  }

  expect_failures = [var.buckets]
}

run "r2_rejects_unknown_cors_method" {
  command = plan

  module {
    source = "./modules/r2"
  }

  variables {
    buckets = {
      uploads = {
        name = "uploads"
        cors_rules = {
          web = {
            allowed_methods = ["TRACE"]
            allowed_origins = ["https://example.com"]
          }
        }
      }
    }
  }

  expect_failures = [var.buckets]
}

# -----------------------------------------------------------------------------
# modules/hyperdrive
# -----------------------------------------------------------------------------

run "hyperdrive_rejects_unknown_scheme" {
  command = plan

  module {
    source = "./modules/hyperdrive"
  }

  variables {
    configs = {
      primary = {
        name = "primary"
        origin = {
          database = "appdb"
          scheme   = "mongodb"
          user     = "app"
          password = "not-a-real-password"
          host     = "db.example.com"
        }
      }
    }
  }

  expect_failures = [var.configs]
}

run "hyperdrive_rejects_origin_without_host_or_service" {
  command = plan

  module {
    source = "./modules/hyperdrive"
  }

  variables {
    configs = {
      primary = {
        name = "primary"
        origin = {
          database = "appdb"
          scheme   = "postgres"
          user     = "app"
          password = "not-a-real-password"
        }
      }
    }
  }

  expect_failures = [var.configs]
}

# -----------------------------------------------------------------------------
# modules/pages
# -----------------------------------------------------------------------------

run "pages_rejects_malformed_project_name" {
  command = plan

  module {
    source = "./modules/pages"
  }

  variables {
    projects = {
      site = { name = "Not_A_Valid_Name", production_branch = "main" }
    }
  }

  expect_failures = [var.projects]
}

run "pages_rejects_unknown_source_type" {
  command = plan

  module {
    source = "./modules/pages"
  }

  variables {
    projects = {
      site = {
        name              = "site"
        production_branch = "main"
        source            = { type = "bitbucket" }
      }
    }
  }

  expect_failures = [var.projects]
}

run "pages_rejects_unknown_env_var_type" {
  command = plan

  module {
    source = "./modules/pages"
  }

  variables {
    projects = {
      site = {
        name              = "site"
        production_branch = "main"
        production = {
          env_vars = {
            TOKEN = { type = "encrypted", value = "x" }
          }
        }
      }
    }
  }

  expect_failures = [var.projects]
}

run "pages_rejects_domain_without_a_project" {
  command = plan

  module {
    source = "./modules/pages"
  }

  variables {
    domains = {
      www = { name = "www.example.com" }
    }
  }

  expect_failures = [var.domains]
}
