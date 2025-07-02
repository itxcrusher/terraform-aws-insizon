############################################################
# outputs.tf – caller consumes these when needed
############################################################
output "arn" {
  description = "IAM user ARN"
  value       = aws_iam_user.this.arn
}

output "access_key_id" {
  description = "Access key ID"
  value       = aws_iam_access_key.this.id
}

output "secret_access_key" {
  description = "Secret access key (plain or PGP-encrypted)"
  sensitive   = true
  value = (
    var.pgp_key != "" ? aws_iam_access_key.this.encrypted_secret : aws_iam_access_key.this.secret
  )
}

output "console_password" {
  description = "Initial console password (if generated)"
  sensitive   = true
  value = (
    length(aws_iam_user_login_profile.this) > 0 ? aws_iam_user_login_profile.this[0].password : null
  )
}
