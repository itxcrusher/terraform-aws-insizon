############################################
# modules/ecr/variables.tf
############################################

variable "app_key" {
  description = "Composite key <app>-<env> (e.g. insizon-app-dev)"
  type        = string
}

variable "cfg" {
  description = "ECR repository configuration"
  type = object({
    create_service   = bool # if false → skip resource entirely
    scan_on_push     = bool # enable ECR vulnerability scans
    service_name     = optional(string)
    lifecycle_policy = optional(string, null)
    #  - null                 → no lifecycle policy
    #  - \"retain-last-20\"   → built-in policy example
    #  - any JSON string      → used verbatim
  })
}
