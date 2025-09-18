variable "account_id" { type = string }
variable "name_prefix" { type = string }
variable "env" { type = string }
variable "project_name" { type = string }
variable "repo_url" { type = string }
variable "buildspec_path" { type = string }
variable "backend_bucket" { type = string }
variable "backend_lock_table_name" { type = string }
variable "github_branch" { type = string }

variable "region" { type = string }
variable "compute_type" { type = string }
variable "image" { type = string }

variable "tags" { type = map(string) }

variable "github_token" {
  description = "Raw GitHub PAT (optional). Prefer github_token_param via SSM."
  type        = string
  default     = null
  sensitive   = true
}

variable "github_token_param" {
  description = "Name of the SSM SecureString parameter storing the PAT (preferred)."
  type        = string
  default     = null
}
