variable "app_key" {
  description = "App-environment key (for tags & naming)"
  type        = string
}

variable "cfg" {
  description = "Per-app CloudFront config + behavior"
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

  validation {
    condition     = length(trimspace(var.cfg.bucket_regional_domain_name)) > 0 && length(trimspace(var.cfg.origin_id)) > 0
    error_message = "bucket_regional_domain_name and origin_id must be non-empty."
  }
}

variable "public_key_ids" {
  description = "Map of public-key alias → CloudFront public key ID (created at root)"
  type        = map(string)
}

variable "key_group_ids" {
  description = "Map of key-group name → CloudFront KeyGroup ID (created at root)"
  type        = map(string)

  validation {
    condition     = contains(keys(var.key_group_ids), var.cfg.key_group_name)
    error_message = "key_group_ids must contain cfg.key_group_name."
  }
}
