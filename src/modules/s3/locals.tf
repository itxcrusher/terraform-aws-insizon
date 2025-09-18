################
#   LOCALS     #
################

locals {
  versioning_status = var.enable_versioning ? "Enabled" : "Suspended"

  # Whether to create CloudFront and wire OAC + bucket policy
  use_cloudfront = try(length(var.cloudfront_cfg.key_names) > 0, false)
}
