output "distribution_domain" {
  description = "CloudFront distribution domain (e.g., dxxxx.cloudfront.net)"
  value       = aws_cloudfront_distribution.this.domain_name
}

output "distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.this.id
}

output "distribution_arn" {
  description = "CloudFront distribution ARN"
  value       = aws_cloudfront_distribution.this.arn
}

output "key_group_key_names" {
  description = "Map of key-group name → list of public key aliases included"
  value       = { (var.cfg.key_group_name) = var.cfg.key_names }
}

output "cloudfront_key_pair_ids" {
  description = "Passthrough: public-key alias → key-id map"
  value       = var.public_key_ids
}
