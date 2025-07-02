output "role_arns" {
  description = "role name → ARN"
  value       = { for k, v in aws_iam_role.this : k => v.arn }
}
