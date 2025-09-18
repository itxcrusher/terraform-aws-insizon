###############################################################################
# modules/s3/cloudfront.tf
#
# Delegates CloudFront work to the dedicated child module.
# That child module:
#   • Creates an Origin Access Control (OAC)
#   • Creates the distribution (trusted key-group configured)
#   • Exposes outputs (distribution_arn/id/domain) used by the S3 policy above
###############################################################################

module "cloudfront" {
  count  = local.use_cloudfront ? 1 : 0
  source = "../cloudfront"

  app_key = var.app_key

  cfg = {
    bucket_regional_domain_name = aws_s3_bucket.main.bucket_regional_domain_name
    origin_id                   = aws_s3_bucket.main.id
    key_group_name              = var.cloudfront_cfg.key_group_name
    key_names                   = var.cloudfront_cfg.key_names
    behavior                    = var.cloudfront_cfg.behavior
  }

  public_key_ids = var.public_key_ids
  key_group_ids  = var.key_group_ids
}
