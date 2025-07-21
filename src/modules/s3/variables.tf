#####################
#   INPUT VARIABLES #
#####################

variable "app_key" {
  description = "App-environment key, e.g. insizon-app-dev"
  type        = string
}

variable "bucket_name" {
  description = "Globally-unique S3 bucket name. Default recommended ⇒ <app_key>-bucket\""
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
  default     = false
}

variable "enable_versioning" {
  description = "Enable S3 versioning"
  type        = bool
  default     = false
}

variable "cloudfront_cfg" {
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

variable "active_public_keys" {
  description = "List of public keys actively referenced by apps"
  type        = list(string)
}

variable "public_key_ids" {
  description = "Map: public key alias → CloudFront key ID"
  type        = map(string)
}

variable "key_group_ids" {
  type = map(string)
}
