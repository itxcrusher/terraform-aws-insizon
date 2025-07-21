# outputs.tf
# Output values from each module for external usage or reference

# --- S3 Buckets with CloudFront ---
output "s3_bucket_names" {
  value = { for k, m in module.s3_module : k => m.s3_bucket_name }
}

output "s3_bucket_arns" {
  value = { for k, m in module.s3_module : k => m.s3_bucket_arn }
}

output "cloudfront_distribution_domains" {
  value = { for k, m in module.s3_module : k => m.cloudfront_distribution_domain }
}

output "cloudfront_distribution_ids" {
  value = { for k, m in module.s3_module : k => m.cloudfront_distribution_id }
}

output "cloudfront_oai_paths" {
  value = { for k, m in module.s3_module : k => m.cloudfront_oai_path }
}

output "cloudfront_public_key_ids" {
  value       = { for k, v in aws_cloudfront_public_key.global_keys : k => v.id }
  description = "Map of alias → CloudFront public key ID"
}

output "key_group_ids" {
  value = {
    for k, v in aws_cloudfront_key_group.global_key_groups : k => v.id
  }
}

# --- S3 Static Uploads ---
output "shared_static_bucket_name" {
  description = "The name of the shared S3 bucket for static files"
  value       = local.static_files_bucket_name
}

output "static_uploads" {
  description = "List of uploaded file keys per app inside the shared static bucket"
  value = {
    for k, m in module.static_s3_upload :
    k => {
      app_name      = m.app_name
      uploaded_keys = m.uploaded_keys
    }
  }
}

# --- Lambda Event Functions ---
output "lambda_function_names_map" {
  value = {
    for k, m in module.lambda_event_module :
    k => values(m.lambda_function_names)
  }
}

# --- Lambda Function URLs ---
output "lambda_function_urls" {
  value = {
    for k, m in module.lambda_event_module :
    k => m.lambda_function_urls
  }
}

# --- Elastic Beanstalk Environments ---
output "beanstalk_environment_urls" {
  value = { for k, m in module.beanstalk_module : k => m.environment_url }
}

# --- ECR Repositories ---
output "ecr_repository_urls" {
  value = { for k, m in module.ecr_module : k => m.repository_url }
}

# --- AWS Budgets ---
output "budget_names" {
  value = { for k, m in module.budgets_module : k => m.budget_name }
}

# --- Secrets from Secrets Manager ---
output "secret_names" {
  value = { for k, m in module.secret_manager_module : k => m.secret_name }
}

# --- SNS Topics ---
output "sns_topic_names" {
  value = {
    for app_key, m in module.sns_module :
    app_key => m.topic_names
  }
}

output "sns_topic_arns" {
  value = {
    for app_key, m in module.sns_module :
    app_key => m.topic_arns
  }
}

output "all_key_groups_to_keys" {
  description = "Map of all CloudFront key groups to their public keys across apps"
  value = merge([
    for app_key, mod in module.s3_module :
    mod.cloudfront_key_group_key_names
  ]...)
}
