variable "cfg" {
  description = "Beanstalk config object (per YAML row)"
  type = object({
    app_name     = string
    env          = string
    service_name = optional(string) # override application name
    platform     = string
    tier         = string                # WebServer | Worker
    env_vars     = optional(map(string)) # simple KV pair list
  })
}

variable "app_key" {
  description = "Convenience key <app>-<env>"
  type        = string
}
