###########################################################################
# variables.tf – keep it minimal; shell/CI sets only "env"
###########################################################################

variable "env" {
  description = "Target environment (dev|qa|prod). Shell/CI sets this."
  type        = string
  validation {
    condition     = contains(["dev", "qa", "prod"], var.env)
    error_message = "env must be one of: dev, qa, prod."
  }
}

# Optional: add extra actions per role without editing modules
variable "extra_role_actions" {
  description = "Optional extra IAM actions per role. e.g. { admin = [\"s3:ListBucket\"] }"
  type        = map(list(string))
  default     = {}
}

variable "export_iam_credentials_csv" {
  description = "If true, write per-user credentials CSVs under private/<env>-bucket/iam_access_keys"
  type        = bool
  default     = true
}
