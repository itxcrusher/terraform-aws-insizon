variable "app_key" {
  description = "Composite key '<app_name>-<env>' (e.g. insizon-app-dev)"
  type        = string
}

variable "cfg" {
  description = "Static upload config (from static-files.yaml)"
  type = object({
    folder_name    = optional(string)           # default "public"
    files_excluded = optional(list(string), []) # exact filenames or globs (simple match)
    bucket_name    = optional(string)           # override default bucket naming
  })
}
