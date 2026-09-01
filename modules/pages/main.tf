# -----------------------------------------------------------------------------
# Submodule: pages
#
# Pages projects and their custom domains. Pages Functions share the developer
# platform storage products with Workers, so the same KV namespace, D1 database
# or R2 bucket can be bound to both.
# -----------------------------------------------------------------------------

locals {
  enabled = var.enabled

  projects = local.enabled ? var.projects : {}
  domains  = local.enabled ? var.domains : {}
}

resource "cloudflare_pages_project" "this" {
  for_each = local.projects

  account_id        = var.account_id
  name              = each.value.name
  production_branch = each.value.production_branch

  build_config = each.value.build_config == null ? null : {
    build_command       = each.value.build_config.build_command
    destination_dir     = each.value.build_config.destination_dir
    root_dir            = each.value.build_config.root_dir
    build_caching       = each.value.build_config.build_caching
    web_analytics_tag   = each.value.build_config.web_analytics_tag
    web_analytics_token = each.value.build_config.web_analytics_token
  }

  source = each.value.source == null ? null : {
    type = each.value.source.type
    config = {
      owner                          = each.value.source.owner
      repo_name                      = each.value.source.repo_name
      production_branch              = coalesce(each.value.source.production_branch, each.value.production_branch)
      production_deployments_enabled = each.value.source.production_deployments_enabled
      pr_comments_enabled            = each.value.source.pr_comments_enabled
      preview_deployment_setting     = each.value.source.preview_deployment_setting
      preview_branch_includes        = each.value.source.preview_branch_includes
      preview_branch_excludes        = each.value.source.preview_branch_excludes
      path_includes                  = each.value.source.path_includes
      path_excludes                  = each.value.source.path_excludes
    }
  }

  deployment_configs = each.value.preview == null && each.value.production == null ? null : {
    preview    = each.value.preview == null ? null : local.deployment_config[each.key].preview
    production = each.value.production == null ? null : local.deployment_config[each.key].production
  }
}

resource "cloudflare_pages_domain" "this" {
  for_each = local.domains

  account_id = var.account_id
  name       = each.value.name

  project_name = (
    each.value.project_key != null
    ? cloudflare_pages_project.this[each.value.project_key].name
    : each.value.project_name
  )
}
