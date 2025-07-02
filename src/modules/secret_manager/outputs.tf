output "secret_name" {
  description = "Name of the generated Secrets Manager secret"
  value       = aws_secretsmanager_secret.this.name
}
