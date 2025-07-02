output "s3_bucket_name" { value = aws_s3_bucket.main.bucket }
output "s3_bucket_arn" { value = aws_s3_bucket.main.arn }

# CloudFront outputs only when module was instantiated
output "cloudfront_distribution_domain" {
  value       = try(module.cloudfront[0].cloudfront_distribution_domain, null)
  description = "Domain for this app’s CloudFront distribution"
}

output "cloudfront_distribution_id" {
  value = try(module.cloudfront[0].cloudfront_distribution_id, null)
}

output "cloudfront_key_pair_ids" {
  value = try(module.cloudfront[0].cloudfront_key_pair_ids, null)
}

output "cloudfront_oai_path" {
  value = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
}

output "cloudfront_key_group_key_names" {
  description = "Bubble-up of key group to public key names map from CloudFront"

  value = length(module.cloudfront) > 0 ? module.cloudfront[0].key_group_key_names : {}
}
