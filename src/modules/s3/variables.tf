#####################
#   INPUT VARIABLES #
#####################

variable "app_key" {
  description = "App-environment key, e.g. insizon-app-dev"
  type        = string
}

variable "bucket_name" {
  description = "Globally-unique S3 bucket name. Default recommended ⇒ <app_key>-bucket"
  type        = string
}

variable "reader_role_arns" {
  description = "IAM role ARNs that can *only* read objects"
  type        = list(string)
}

variable "writer_role_arns" {
  description = "IAM role ARNs that can put/delete objects"
  type        = list(string)
}

variable "enable_bucket_encryption" {
  description = "Enable AES-256 server-side encryption"
  type        = bool
}

variable "enable_versioning" {
  description = "Enable S3 versioning"
  type        = bool
}

# CloudFront wiring (shared key-group + behavior comes from higher-level config)
variable "cloudfront_cfg" {
  description = "CloudFront distribution config for this app's bucket front-end"
  type = object({
    key_group_name = string
    key_names      = list(string)
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
}

# Public key inventory for the shared key-group
variable "active_public_keys" {
  description = "List of public keys actively referenced by apps (not directly used here; kept for interface parity)"
  type        = list(string)
}

variable "public_key_ids" {
  description = "Map: public key alias → CloudFront public key ID"
  type        = map(string)
}

variable "key_group_ids" {
  description = "Map: key_group_name → CloudFront key group ID"
  type        = map(string)
}
