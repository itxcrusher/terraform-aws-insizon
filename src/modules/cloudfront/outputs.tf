output "cloudfront_distribution_domain" { value = aws_cloudfront_distribution.this.domain_name }
output "cloudfront_distribution_id" { value = aws_cloudfront_distribution.this.id }
output "cloudfront_key_pair_ids" {
  value       = { for k, v in aws_cloudfront_public_key.this : k => v.id }
  description = "Map: public-key alias → key-id"
}

output "key_group_key_names" {
  description = "Map of key group → list of public key names in that group"
  value = {
    (aws_cloudfront_key_group.shared.name) = [
      for pk in aws_cloudfront_public_key.this : pk.name
    ]
  }
}
