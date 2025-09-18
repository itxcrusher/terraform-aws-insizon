output "s3_bucket_name" { value = aws_s3_bucket.main.bucket }
output "s3_bucket_arn" { value = aws_s3_bucket.main.arn }

output "cloudfront_distribution_domain" {
  description = "Domain for this app's CloudFront distribution"
  value       = try(module.cloudfront[0].distribution_domain, null)
}

output "cloudfront_distribution_id" {
  description = "Distribution ID for this app's CloudFront distribution"
  value       = try(module.cloudfront[0].distribution_id, null)
}

output "cloudfront_distribution_arn" {
  description = "Distribution ARN for this app's CloudFront distribution"
  value       = try(module.cloudfront[0].distribution_arn, null)
}

output "cloudfront_key_pair_ids" {
  description = "Map: public-key alias → CloudFront public key ID"
  value       = try(module.cloudfront[0].cloudfront_key_pair_ids, {})
}

output "cloudfront_key_group_key_names" {
  description = "Map of key-group → public-key aliases"
  value       = length(module.cloudfront) > 0 ? module.cloudfront[0].key_group_key_names : {}
}
