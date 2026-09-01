output "derived_bindings" {
  description = "The binding map the root module built from the storage it created."
  value       = module.derived.bindings
  sensitive   = true
}

output "explicit_script_name" {
  description = "Name of the Worker whose bindings were written by hand."
  value       = module.explicit.script_name
}

output "shared_namespace_ids" {
  description = "IDs of the standalone KV namespaces."
  value       = module.storage.namespace_ids
}
