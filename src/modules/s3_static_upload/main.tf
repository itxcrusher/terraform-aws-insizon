###############################################
# S3 Static Upload – main.tf
###############################################

# ---------------------------------------------------------------------
# S3 bucket (public static website).  Bucket name can be overridden in
# YAML; otherwise defaults to "<app_key>-static-bucket".
# ---------------------------------------------------------------------
resource "aws_s3_bucket" "static" {
  bucket = coalesce(
    var.cfg.bucket_name,
    "${var.app_key}-static-bucket"
  )

  tags = {
    Project     = "StaticSite"
    Application = local.app_name
    Environment = local.env
    ManagedBy   = "Terraform"
  }
}

# ---------------------------------------------------------------------
# Public access (website style) – keep it simple, but be aware of
# security if you ever host sensitive data.
# ---------------------------------------------------------------------
resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.static.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "allow_public" {
  bucket = aws_s3_bucket.static.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicRead"
      Effect    = "Allow"
      Principal = "*"
      Action    = ["s3:GetObject"]
      Resource  = "${aws_s3_bucket.static.arn}/*"
    }]
  })

  depends_on = [
    aws_s3_bucket_public_access_block.this
  ]
}

# ---------------------------------------------------------------------
# Upload every file under source_dir (minus exclusions)
# ---------------------------------------------------------------------
resource "aws_s3_object" "static_files" {
  for_each = { for f in local.upload_files : f => f }

  bucket = aws_s3_bucket.static.id
  key    = each.key

  # Absolute path on local disk
  source = "${local.source_dir}/${each.key}"

  etag = filemd5("${local.source_dir}/${each.key}")

  content_type = lookup(
    local.mime_map,
    lower(regex("[^.]+$", each.key)),
    "binary/octet-stream"
  )
}
