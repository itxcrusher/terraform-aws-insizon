#########################################
# Locals – small helpers for exports
#########################################

# Only include aliases that actually exist in public_key_ids to avoid plan errors.
locals {
  _csv_rows = [
    for alias in var.cfg.key_names :
    "${var.public_key_ids[alias]},${aws_cloudfront_distribution.this.domain_name},${var.cfg.origin_id}"
    if contains(keys(var.public_key_ids), alias)
  ]

  cloudfront_csv_content = join("\n",
    concat(
      ["Aws_CloudFront_KeyPairId,Aws_Cloudfront_DistributionSubdomain,S3_Bucket"],
      local._csv_rows
    )
  )
}
