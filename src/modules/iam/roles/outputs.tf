# Map of base key -> ARN (unchanged API)
output "role_arns" {
  description = "ARNs for all IAM roles created by this module."
  value       = { for k, r in aws_iam_role.this : k => r.arn }
}

# Map of base key -> physical role name (env-scoped)
output "role_names" {
  description = "Concrete role names created (env-scoped)."
  value       = local.role_names
}
