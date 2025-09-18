resource "aws_cloudfront_origin_access_control" "this" {
  name                              = "${var.app_key}-oac"
  description                       = "S3 OAC for ${var.app_key}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

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
    compress               = true

    forwarded_values {
      query_string = true
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

  tags = {
    ManagedBy = "Terraform"
    AppKey    = var.app_key
  }
}
