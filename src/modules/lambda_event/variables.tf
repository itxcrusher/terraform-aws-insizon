###########################################################################
# variables.tf – contract for lambda_event module
###########################################################################

variable "app_key" {
  description = "App + env identifier (e.g. insizon-app-dev); used for names only."
  type        = string
}

variable "functions" {
  description = "List of Lambda function definitions pulled straight from lambda-event.yaml"
  type = list(object({
    function_name  = string
    create_service = bool
    runtime        = string
    handler        = string
    role_policy    = list(string) # AWS managed policy names (short form)
    memory_size    = number
    timeout        = number
    env_vars       = map(string)

    triggers = list(object({
      type     = string           # 'http' | 'cron'
      schedule = optional(string) # required when type == 'cron'
    }))
  }))
}
