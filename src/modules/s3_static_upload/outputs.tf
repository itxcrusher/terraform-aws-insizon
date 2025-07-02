output "bucket_name" {
  description = "Bucket that hosts static files"
  value       = aws_s3_bucket.static.bucket
}
