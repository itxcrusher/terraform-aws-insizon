variable "cfg" {
  description = "Static upload config (from static-files.yaml)"
  type = object({
    app_name       = string
    bucket_name    = string
    files_excluded = optional(list(string), [])
  })
}

variable "source_dir" {
  description = "Absolute/relative path on local disk where app's static files live (e.g., ../private/<env-bucket>/<static_root>/<app_name>)"
  type        = string

  validation {
    condition     = length(trimspace(var.source_dir)) > 0
    error_message = "source_dir must be a non-empty path."
  }
}
