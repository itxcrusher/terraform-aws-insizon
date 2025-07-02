locals {
  # Fallback: if service_name absent, use app_name
  service_name = coalesce(var.cfg.service_name, var.cfg.app_name)

  # Convert env_vars map → list(object) required by EB ‘setting’
  env_vars_kv = flatten([
    for k, v in lookup(var.cfg, "env_vars", {}) :
    [{
      name  = k
      value = v
    }]
  ])
}
