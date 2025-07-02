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
