###########################################################################
# variables.tf – all external knobs
###########################################################################

variable "env_filter" {
  description = <<EOT
If set (dev / qa / prod), only that environment’s stacks are deployed.
Empty string builds everything found in apps.yaml.
EOT
  type        = string
  default     = ""
}

# ------------------------------------------------------------------------
# YAML locations (override in CLI if you move them)
# ------------------------------------------------------------------------
variable "user_roles_yaml" { default = "./config/user-roles.yaml" }
variable "apps_yaml" { default = "./config/apps.yaml" }
variable "beanstalk_yaml" { default = "./config/elasticbeanstalk.yaml" }
variable "ecr_yaml" { default = "./config/ecr.yaml" }
variable "budget_yaml" { default = "./config/budget.yaml" }
variable "cloudfront_yaml" { default = "./config/cloudfront.yaml" } # ⟵ renamed
variable "lambda_yaml" { default = "./config/lambda-event.yaml" }
variable "static_files_yaml" { default = "./config/static-files.yaml" }
variable "sns_yaml" { default = "./config/sns.yaml" }

# ------------------------------------------------------------------------
# Extra IAM privileges per role (rarely needed)
# ------------------------------------------------------------------------
variable "extra_role_actions" {
  description = "Optional extra IAM actions per role. e.g. { admin = [\"s3:ListBucket\"] }"
  type        = map(list(string))
  default     = {}
}
