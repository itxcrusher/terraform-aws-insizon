###########################################################################
# locals.tf – classify and flatten inputs
###########################################################################

locals {
  # Build only items with create_service = true
  valid_functions = {
    for f in var.functions :
    f.function_name => f if f.create_service
  }

  http_functions = {
    for k, f in local.valid_functions :
    k => f if length([for t in f.triggers : t if lower(t.type) == "http"]) > 0
  }

  cron_functions = {
    for k, f in local.valid_functions :
    k => f if length([for t in f.triggers : t if lower(t.type) == "cron"]) > 0
  }

  # Flatten policy attachment list
  flattened_lambda_policies = flatten([
    for fn, cfg in local.valid_functions : [
      for p in cfg.role_policy : {
        key    = "${fn}-${p}"
        name   = fn
        policy = p
      }
    ]
  ])

  # Resolve artifact path per function (fail-fast if missing)
  artifact_path = {
    for fn, _ in local.valid_functions :
    fn => var.artifacts[fn]
  }
}
