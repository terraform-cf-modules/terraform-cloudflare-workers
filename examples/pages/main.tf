# A Pages project with git integration, a custom domain, and Functions bound to
# the same KV namespace and D1 database a Worker uses.
#
# Pages Functions take their bindings in a different shape from Workers: one map
# per binding kind rather than one list with a type discriminator. modules/pages
# hides that difference, but the values still come from the same resources.

provider "cloudflare" {
  # Reads CLOUDFLARE_API_TOKEN from the environment.
}

module "storage" {
  source = "../../"

  account_id = var.account_id

  kv_namespaces = {
    sessions = { title = "site-sessions" }
  }

  d1_databases = {
    content = { name = "site-content" }
  }
}

module "site" {
  source = "../../modules/pages"

  account_id = var.account_id

  projects = {
    site = {
      name              = "example-site"
      production_branch = "main"

      build_config = {
        build_command   = "npm run build"
        destination_dir = "dist"
        root_dir        = "."
        build_caching   = true
      }

      source = {
        type                           = "github"
        owner                          = "example-org"
        repo_name                      = "example-site"
        production_deployments_enabled = true
        pr_comments_enabled            = true
        preview_deployment_setting     = "custom"
        preview_branch_includes        = ["develop", "feature/*"]
        preview_branch_excludes        = ["wip/*"]
        path_excludes                  = ["docs/*"]
      }

      production = {
        compatibility_date  = "2025-06-01"
        compatibility_flags = ["nodejs_compat"]
        cpu_ms              = 50

        kv_namespaces = {
          SESSIONS = module.storage.kv_namespace_ids["sessions"]
        }

        d1_databases = {
          CONTENT = module.storage.d1_database_ids["content"]
        }

        env_vars = {
          NODE_VERSION = { type = "plain_text", value = "20" }
          API_BASE     = { type = "plain_text", value = "https://api.example.com" }
        }
      }

      preview = {
        compatibility_date = "2025-06-01"

        kv_namespaces = {
          SESSIONS = module.storage.kv_namespace_ids["sessions"]
        }

        env_vars = {
          NODE_VERSION = { type = "plain_text", value = "20" }
          API_BASE     = { type = "plain_text", value = "https://staging-api.example.com" }
        }
      }
    }
  }

  domains = {
    www = {
      name        = "www.example.com"
      project_key = "site"
    }
  }
}
