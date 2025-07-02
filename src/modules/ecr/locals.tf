locals {
  # If service_name is omitted, fall back to the app_key ("app-env")
  repo_name = coalesce(var.cfg.service_name, var.app_key)

  # Simple example lifecycle-policy JSON (used only when cfg.lifecycle_policy set)
  default_lifecycle_policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Retain last 20 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 20
      }
      action = { type = "expire" }
    }]
  })
}
