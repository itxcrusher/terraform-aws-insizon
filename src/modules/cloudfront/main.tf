###############################################################################
# modules/cloudfront/main.tf
#
# Creates (once per calling app):
#   • Public keys (for each alias passed)
#   • Adds/creates the shared key-group (key_group_name)
#   • Origin-Access-Control
#   • CloudFront distribution fronting the S3 bucket
###############################################################################

# Moved the following logic to root locals
############################
# 1. Public keys
############################
# data "local_file" "public_keys" {
#   for_each = {
#     for alias in var.cfg.key_names :
#     alias => "${path.module}/../../../private/cloudfront/rsa_keys/public/${alias}-public-key.pem"
#     if contains(var.active_keys, alias)
#   }

#   filename = each.value
# }

# resource "aws_cloudfront_public_key" "this" {
#   for_each = data.local_file.public_keys

#   name        = "${each.key}-public-key-${substr(md5(each.value.content), 0, 8)}"
#   comment     = "Public key for ${each.key}"
#   encoded_key = each.value.content

#   lifecycle {
#     create_before_destroy = true
#     ignore_changes        = [encoded_key]
#   }
# }

############################
# 2. Shared key-group
############################
# resource "aws_cloudfront_key_group" "shared" {
#   name    = var.cfg.key_group_name
#   comment = "Shared key-group managed by Terraform"

#   items = [for alias in var.cfg.key_names : var.public_key_ids[alias]]

# }

############################
# 3. Origin-Access-Control
############################
resource "aws_cloudfront_origin_access_control" "this" {
  name                              = "${var.app_key}-oac"
  description                       = "S3 OAC for ${var.app_key}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

############################
# 4. Distribution
############################
resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  comment             = "${var.app_key}-distribution"
  price_class         = var.cfg.behavior.price_class
  default_root_object = var.cfg.behavior.default_root_object

  origin {
    domain_name              = var.cfg.bucket_regional_domain_name
    origin_id                = var.cfg.origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
  }

  default_cache_behavior {
    target_origin_id       = var.cfg.origin_id
    viewer_protocol_policy = var.cfg.behavior.viewer_protocol_policy
    allowed_methods        = var.cfg.behavior.allowed_methods
    cached_methods         = var.cfg.behavior.cached_methods

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    trusted_key_groups = [var.key_group_ids[var.cfg.key_group_name]]
  }

  restrictions {
    geo_restriction {
      restriction_type = var.cfg.behavior.geo_restriction.restriction_type
      locations        = var.cfg.behavior.geo_restriction.locations
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

############################
# 5. Create CSV export
############################
resource "local_file" "cloudfront_csv_export" {
  content  = local.cloudfront_csv_content
  filename = "${path.module}/../../../private/cloudfront/id/${var.app_key}-KeyPair-n-DistributionSubdomain.csv"
}
