variable "cfg" {
  description = "Static upload config (from static-files.yaml)"
  type = object({
    app_name       = string
    bucket_name    = string
    files_excluded = optional(list(string), [])
  })
}
