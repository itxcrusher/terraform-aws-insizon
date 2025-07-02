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
  active_keys = var.active_public_keys
}
