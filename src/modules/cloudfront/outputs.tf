output "cloudfront_distribution_domain" { value = aws_cloudfront_distribution.this.domain_name }
output "cloudfront_distribution_id" { value = aws_cloudfront_distribution.this.id }
output "cloudfront_key_pair_ids" {
  value       = var.public_key_ids
  description = "Map: public-key alias → key-id (passed from root)"
}

output "key_group_key_names" {
  description = "Map of key group → list of public key names in that group"
  value = {
    (var.cfg.key_group_name) = var.cfg.key_names
  }
}
