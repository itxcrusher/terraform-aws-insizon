output "secret_name" {
  description = "Name of the generated Secrets Manager secret"
  value       = aws_secretsmanager_secret.this.name
}

output "secrets_sha256" {
  value     = sha256(jsonencode(local.final_secrets))
  sensitive = true
}
