############################################
# modules/ecr/outputs.tf
############################################

# Index with try() so outputs resolve to null when
# create_service = false (count = 0).

output "ecr_repo_name" {
  description = "Name of the ECR repository"
  value       = try(aws_ecr_repository.main[0].name, null)
}

output "repository_url" {
  description = "Full ECR repository URL"
  value       = try(aws_ecr_repository.main[0].repository_url, null)
}
