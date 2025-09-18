###########################################################################
# variables.tf – contract for lambda_event module
###########################################################################

variable "app_key" {
  description = "App + env identifier (e.g. insizon-dev); used for names only."
  type        = string
}

variable "functions" {
  description = "List of Lambda function definitions pulled straight from lambda-event.yaml"
  type = list(object({
    function_name  = string
    create_service = bool
    runtime        = string
    handler        = string
    # Accept full ARNs (recommended). If you pass short names, pass their ARNs here.
    role_policy = list(string)
    memory_size = number
    timeout     = number
    env_vars    = map(string)

    triggers = list(object({
      type     = string           # 'http' | 'cron'
      schedule = optional(string) # required when type == 'cron'
    }))
  }))
}

variable "artifacts" {
  description = <<EOT
Map of function_name => absolute/relative path to the deployable .zip for that function.
Example:
  {
    post-to-insizon = "../private/dev/lambda/insizon-dev/post-to-insizon.zip"
  }
EOT
  type        = map(string)

  validation {
    condition     = length(keys(var.artifacts)) >= 1
    error_message = "artifacts map must contain at least one entry (function_name => zip path)."
  }
}
