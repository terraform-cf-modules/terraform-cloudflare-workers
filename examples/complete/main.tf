# Every optional feature of the Cloudflare Workers module turned on: a Worker
# with routes, a custom domain, cron triggers, all five storage products bound
# automatically, extra hand written bindings, and a Pages project.

provider "cloudflare" {
  # Reads CLOUDFLARE_API_TOKEN from the environment.
}

module "this" {
  source = "../../"

  enabled    = true
  account_id = var.account_id
  zone_id    = var.zone_id

  # ---------------------------------------------------------------------------
  # The Worker
  # ---------------------------------------------------------------------------

  script_name         = "complete-worker"
  deployment_model    = "script"
  compatibility_date  = "2025-06-01"
  compatibility_flags = ["nodejs_compat"]
  main_module         = "worker.js"
  content_type        = "application/javascript+module"
  usage_model         = "standard"
  logpush             = true

  content = <<-JS
    export default {
      async fetch(request, env, ctx) {
        await env.CACHE.put("last-seen", new Date().toISOString());
        return new Response("ok");
      },
      async scheduled(event, env, ctx) {
        await env.JOBS.send({ ranAt: event.scheduledTime });
      },
      async queue(batch, env, ctx) {
        for (const message of batch.messages) {
          message.ack();
        }
      },
    };
  JS

  limits = {
    cpu_ms      = 50
    subrequests = 100
  }

  placement_mode = "smart"

  observability = {
    enabled            = true
    head_sampling_rate = 1
    logs = {
      enabled         = true
      invocation_logs = true
      destinations    = ["cloudflare"]
    }
    traces = {
      enabled            = true
      destinations       = ["cloudflare"]
      propagation_policy = "authenticated"
    }
  }

  tail_consumers = {
    logger = { service = "log-collector" }
  }

  migrations = {
    new_tag            = "v1"
    new_sqlite_classes = ["Counter"]
  }

  assets = {
    directory = "./public"
    config = {
      html_handling      = "auto-trailing-slash"
      not_found_handling = "single-page-application"
    }
  }

  workers_dev = {
    enabled          = true
    previews_enabled = true
  }

  keep_bindings = ["secret_text"]

  # ---------------------------------------------------------------------------
  # Storage. Each entry with a `binding` is wired into the Worker for you.
  # ---------------------------------------------------------------------------

  kv_namespaces = {
    cache = {
      title   = "complete-worker-cache"
      binding = "CACHE"
    }
    flags = {
      title = "complete-worker-flags"
    }
  }

  kv_pairs = {
    greeting = {
      namespace_key = "flags"
      key_name      = "greeting"
      value         = "hello"
      metadata      = jsonencode({ owner = "platform" })
    }
  }

  d1_databases = {
    app = {
      name                  = "complete-worker-app"
      primary_location_hint = "weur"
      read_replication_mode = "auto"
      binding               = "DB"
    }
  }

  queues = {
    jobs = {
      queue_name               = "complete-worker-jobs"
      message_retention_period = 345600
      delivery_delay           = 0
      binding                  = "JOBS"

      # script_name left null, so the Worker above becomes the consumer.
      consumer = {
        type             = "worker"
        batch_size       = 10
        max_retries      = 3
        max_wait_time_ms = 500
        retry_delay      = 30
      }
    }
  }

  r2_buckets = {
    uploads = {
      name          = "complete-worker-uploads"
      location      = "weur"
      storage_class = "Standard"
      binding       = "UPLOADS"

      cors_rules = {
        web = {
          allowed_methods = ["GET", "HEAD"]
          allowed_origins = ["https://app.example.com"]
          allowed_headers = ["content-type"]
          expose_headers  = ["etag"]
          max_age_seconds = 3600
        }
      }

      lifecycle_rules = {
        expire-temp = {
          prefix                             = "tmp/"
          delete_objects_after_days          = 30
          abort_multipart_uploads_after_days = 7

          storage_class_transitions = {
            cool = {
              storage_class = "InfrequentAccess"
              after_days    = 7
            }
          }
        }
      }

      lock_rules = {
        retain-audit = {
          prefix          = "audit/"
          condition_type  = "Age"
          max_age_seconds = 2592000
        }
      }

      custom_domains = {
        cdn = {
          domain  = "cdn.example.com"
          zone_id = var.zone_id
          min_tls = "1.2"
        }
      }
    }
  }

  hyperdrive_configs = {
    primary = {
      name    = "complete-worker-primary"
      binding = "HYPERDRIVE"

      origin = {
        database = "appdb"
        scheme   = "postgres"
        user     = "app"
        password = var.origin_password
        host     = "db.internal.example.com"
        port     = 5432
      }

      origin_connection_limit = 20

      caching = {
        disabled               = false
        max_age                = 60
        stale_while_revalidate = 15
      }
    }
  }

  # ---------------------------------------------------------------------------
  # Bindings this module cannot derive
  # ---------------------------------------------------------------------------

  bindings = {
    ENVIRONMENT = {
      type = "plain_text"
      text = "production"
    }
    FEATURE_FLAGS = {
      type = "json"
      json = jsonencode({ newCheckout = true })
    }
    AI = {
      type = "ai"
    }
    COUNTER = {
      type       = "durable_object_namespace"
      class_name = "Counter"
    }
    THROTTLE = {
      type = "ratelimit"
      simple = {
        limit  = 100
        period = 60
      }
    }
  }

  # ---------------------------------------------------------------------------
  # Triggers
  # ---------------------------------------------------------------------------

  routes = {
    api  = { pattern = "example.com/api/*" }
    root = { pattern = "example.com/*" }
  }

  custom_domains = {
    api = {
      hostname = "worker.example.com"
      zone_id  = var.zone_id
    }
  }

  cron_schedules = ["*/15 * * * *", "@daily"]

  # ---------------------------------------------------------------------------
  # Pages
  # ---------------------------------------------------------------------------

  pages_projects = {
    site = {
      name              = "complete-site"
      production_branch = "main"

      build_config = {
        build_command   = "npm run build"
        destination_dir = "dist"
        build_caching   = true
      }

      source = {
        type                       = "github"
        owner                      = "example-org"
        repo_name                  = "example-site"
        preview_deployment_setting = "custom"
        preview_branch_includes    = ["develop"]
      }

      production = {
        compatibility_date  = "2025-06-01"
        compatibility_flags = ["nodejs_compat"]

        env_vars = {
          NODE_VERSION = { type = "plain_text", value = "20" }
        }
      }

      preview = {
        compatibility_date = "2025-06-01"

        env_vars = {
          NODE_VERSION = { type = "plain_text", value = "20" }
        }
      }
    }
  }

  pages_domains = {
    apex = {
      name        = "www.example.com"
      project_key = "site"
    }
  }
}
