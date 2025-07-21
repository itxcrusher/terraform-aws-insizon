variable "app_key" {
  description = "App-environment key (for tags & naming)"
  type        = string
}

variable "cfg" {
  type = object({
    bucket_regional_domain_name = string
    origin_id                   = string
    key_group_name              = string
    key_names                   = list(string)
    behavior = object({
      default_root_object    = string
      price_class            = string
      viewer_protocol_policy = string
      allowed_methods        = list(string)
      cached_methods         = list(string)
      geo_restriction = object({
        restriction_type = string
        locations        = list(string)
      })
    })
  })

  validation {
    condition     = length(var.cfg.key_names) <= 100
    error_message = "An AWS Key Group supports at most 100 public keys."
  }
}

variable "public_key_ids" {
  description = "Map of public key alias → CloudFront public key ID, passed from root"
  type        = map(string)
}

variable "key_group_ids" {
  type        = map(string)
  description = "Map of key alias to CloudFront key group IDs"
}
