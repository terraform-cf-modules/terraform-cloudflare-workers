# Minimum viable configuration for the Cloudflare Workers module: one Worker,
# served on its workers.dev subdomain.

provider "cloudflare" {
  # Reads CLOUDFLARE_API_TOKEN from the environment.
}

module "this" {
  source = "../../"

  enabled    = true
  account_id = var.account_id

  script_name        = "hello-worker"
  compatibility_date = "2025-06-01"

  content = <<-JS
    export default {
      async fetch(request, env, ctx) {
        return new Response("hello from terraform");
      },
    };
  JS

  workers_dev = {
    enabled = true
  }
}
