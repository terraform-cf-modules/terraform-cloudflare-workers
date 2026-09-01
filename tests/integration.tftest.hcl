# Applies against a real Cloudflare test account.
# Runs on a schedule and on manual dispatch only, never on pull requests,
# because fork pull requests cannot read organisation secrets.

variables {
  account_id = null # supplied by TF_VAR_account_id
  zone_id    = null # supplied by TF_VAR_zone_id

  script_name        = "tf-integration-worker"
  compatibility_date = "2025-06-01"
  content            = "export default { async fetch() { return new Response('ok'); } };"

  kv_namespaces = {
    cache = { title = "tf-integration-cache", binding = "CACHE" }
  }

  kv_pairs = {
    greeting = {
      namespace_key = "cache"
      key_name      = "greeting"
      value         = "hello"
    }
  }

  d1_databases = {
    app = { name = "tf-integration-app", binding = "DB" }
  }

  queues = {
    jobs = {
      queue_name = "tf-integration-jobs"
      binding    = "JOBS"
    }
  }

  r2_buckets = {
    uploads = { name = "tf-integration-uploads", binding = "UPLOADS" }
  }

  bindings = {
    ENVIRONMENT = { type = "plain_text", text = "integration" }
  }

  cron_schedules = ["0 3 * * *"]

  workers_dev = { enabled = true }
}

run "apply_and_destroy" {
  command = apply

  assert {
    condition     = output.enabled == true
    error_message = "Module did not report enabled after apply."
  }

  assert {
    condition     = output.script_name == "tf-integration-worker"
    error_message = "Module did not deploy the Worker it was asked to deploy."
  }

  assert {
    condition     = length(output.kv_namespace_ids) == 1
    error_message = "KV namespace was not created."
  }

  assert {
    condition     = length(output.d1_database_ids) == 1
    error_message = "D1 database was not created."
  }

  assert {
    condition     = length(output.queue_ids) == 1
    error_message = "Queue was not created."
  }

  assert {
    condition     = length(output.r2_bucket_names) == 1
    error_message = "R2 bucket was not created."
  }

  assert {
    condition     = length(output.cron_triggers) == 1
    error_message = "Cron trigger was not created."
  }

  assert {
    condition     = output.subdomain != null
    error_message = "workers.dev subdomain was not configured."
  }
}
