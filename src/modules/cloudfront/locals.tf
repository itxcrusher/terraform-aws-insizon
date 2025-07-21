locals {
  cloudfront_csv_content = join("\n",
    concat(
      ["Aws_CloudFront_KeyPairId,Aws_Cloudfront_DistributionSubdomain,S3_Bucket"],
      [
        for alias, id in var.public_key_ids :
        "${id},${aws_cloudfront_distribution.this.domain_name},${var.cfg.origin_id}"
      ]
    )
  )
}
