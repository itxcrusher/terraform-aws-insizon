############################################################
# secret_manager – variables.tf
############################################################

variable "app_key" {
  description = "Composite key '<app>-<env>', used in secret name."
  type        = string
}

# ------------  AWS runtime creds (sensitive)  -------------
variable "iam_access_key_id" {
  type      = string
  sensitive = true
}

variable "iam_secret_access_key" {
  type      = string
  sensitive = true
}

# ------------  CloudFront runtime data  -------------------
variable "cloudfront_key_pair_ids" {
  description = "Map of public-key name → key-pair ID"
  type        = map(string)
}

variable "cloudfront_distribution_domain" {
  type = string
}

variable "cloudfront_private_key" {
  type      = string
  sensitive = true
}

variable "cloudfront_key_alias" {
  description = "Selected public-key alias for this app's signing key pair"
  type        = string
}

# ------------  S3 ------------------------------------------------------
variable "s3_bucket_name" {
  type = string
}

# ------------  YAML with static secrets -------------------------------
variable "yaml_file_path" {
  description = "Absolute path to per-app secrets YAML (may be empty)."
  type        = string
}
