variable "role_matrix" {
  description = "Role definitions built in root locals"
  type = map(object({
    base_actions   = list(string)
    extra_actions  = list(string)
    principal_arns = list(string)
    type           = string # readonly | privileged
  }))
}

variable "tags" {
  description = "Common tags applied to every role"
  type        = map(string)
  default     = {}
}

variable "env" {
  description = "Environment suffix to make role names unique per env (e.g., dev|qa|prod)"
  type        = string
}

variable "name_prefix" {
  description = "Optional prefix for role names (e.g., insizon-)"
  type        = string
  default     = ""
}

variable "name_suffix" {
  description = "Optional suffix after env (rarely needed)"
  type        = string
  default     = ""
}
