locals {
  versioning_status = var.enable_versioning ? "Enabled" : "Suspended"

  use_cloudfront = try(length(var.cloudfront_cfg.key_names) > 0, false)
}
