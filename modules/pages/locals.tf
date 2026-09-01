# Pages Functions bindings use a different shape from Worker bindings: one map per binding kind rather than a
# single list with a `type` discriminator. Callers give the flat, readable form; this translates it.

locals {
  pages_env_inputs = merge(
    { for pk, p in local.projects : "${pk}//preview" => p.preview if p.preview != null },
    { for pk, p in local.projects : "${pk}//production" => p.production if p.production != null },
  )

  pages_env = {
    for k, e in local.pages_env_inputs : k => {
      compatibility_date                   = e.compatibility_date
      compatibility_flags                  = e.compatibility_flags
      always_use_latest_compatibility_date = e.always_use_latest_compatibility_date
      build_image_major_version            = e.build_image_major_version
      fail_open                            = e.fail_open
      wrangler_config_hash                 = null

      limits    = e.cpu_ms == null ? null : { cpu_ms = e.cpu_ms }
      placement = e.placement_mode == null ? null : { mode = e.placement_mode }

      env_vars = length(e.env_vars) == 0 ? null : {
        for name, v in e.env_vars : name => { type = v.type, value = v.value }
      }

      ai_bindings = length(e.ai_bindings) == 0 ? null : {
        for name, v in e.ai_bindings : name => { project_id = v }
      }

      analytics_engine_datasets = length(e.analytics_engine_datasets) == 0 ? null : {
        for name, v in e.analytics_engine_datasets : name => { dataset = v }
      }

      browsers = length(e.browsers) == 0 ? null : { for name in e.browsers : name => {} }

      d1_databases = length(e.d1_databases) == 0 ? null : {
        for name, v in e.d1_databases : name => { id = v }
      }

      durable_object_namespaces = length(e.durable_object_namespaces) == 0 ? null : {
        for name, v in e.durable_object_namespaces : name => { namespace_id = v }
      }

      hyperdrive_bindings = length(e.hyperdrive_bindings) == 0 ? null : {
        for name, v in e.hyperdrive_bindings : name => { id = v }
      }

      kv_namespaces = length(e.kv_namespaces) == 0 ? null : {
        for name, v in e.kv_namespaces : name => { namespace_id = v }
      }

      mtls_certificates = length(e.mtls_certificates) == 0 ? null : {
        for name, v in e.mtls_certificates : name => { certificate_id = v }
      }

      queue_producers = length(e.queue_producers) == 0 ? null : {
        for name, v in e.queue_producers : name => { name = v }
      }

      r2_buckets = length(e.r2_buckets) == 0 ? null : {
        for name, v in e.r2_buckets : name => { name = v.name, jurisdiction = v.jurisdiction }
      }

      services = length(e.services) == 0 ? null : {
        for name, v in e.services : name => {
          service     = v.service
          environment = v.environment
          entrypoint  = v.entrypoint
        }
      }

      vectorize_bindings = length(e.vectorize_bindings) == 0 ? null : {
        for name, v in e.vectorize_bindings : name => { index_name = v }
      }
    }
  }

  deployment_config = {
    for pk, p in local.projects : pk => {
      preview    = try(local.pages_env["${pk}//preview"], null)
      production = try(local.pages_env["${pk}//production"], null)
    }
  }
}
