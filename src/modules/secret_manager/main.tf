############################################################
# secret_manager – main.tf
############################################################

# AWS Secrets Manager secret (logical container)
resource "aws_secretsmanager_secret" "this" {
  name        = "${var.app_key}-secrets-manager"
  description = "Runtime + static secrets for ${var.app_key}"

  recovery_window_in_days = 0 # delete instantly on destroy

  lifecycle {
    create_before_destroy = true # zero-downtime rotation
  }
}

# Current version with all key/value pairs
resource "aws_secretsmanager_secret_version" "current" {
  secret_id      = aws_secretsmanager_secret.this.id
  secret_string  = jsonencode(local.final_secrets)
  version_stages = ["AWSCURRENT"]
}
