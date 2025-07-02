###############################################################################
# modules/s3/main.tf
#
# Creates:
#   • Private S3 bucket (versioning/encryption optional)
#   • Origin-Access-Identity for CloudFront
#   • Bucket policy granting:
#       – OAI read
#       – reader_role_arns read (if non-empty)
#       – writer_role_arns put/delete (if non-empty)
#       – TLS-only access
#   • (Optionally) a CloudFront distribution that re-uses a shared key-group
###############################################################################

############################
# 1. Bucket core
############################
resource "aws_s3_bucket" "main" {
  bucket = var.bucket_name

  tags = {
    ManagedBy = "Terraform"
    AppKey    = var.app_key
  }
}

resource "aws_s3_bucket_ownership_controls" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "main" {
  bucket     = aws_s3_bucket.main.id
  acl        = "private"
  depends_on = [aws_s3_bucket_ownership_controls.main]
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket                  = aws_s3_bucket.main.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

############################
# 2. Versioning & Encryption
############################
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  count  = var.enable_bucket_encryption ? 1 : 0
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

############################
# 3. Origin-Access-Identity
############################
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "${var.app_key}-oai"
}

############################
# 4. Bucket-policy
############################
data "aws_iam_policy_document" "main" {
  # Allow CloudFront (OAI) READ
  statement {
    sid = "AllowCloudFrontRead"
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.oai.iam_arn]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.main.arn}/*"]
  }

  # Conditionally allow READ for reader roles
  dynamic "statement" {
    for_each = length(var.reader_role_arns) > 0 ? [1] : []
    content {
      sid = "AllowRolesRead"
      principals {
        type        = "AWS"
        identifiers = var.reader_role_arns
      }
      actions   = ["s3:GetObject"]
      resources = ["${aws_s3_bucket.main.arn}/*"]
    }
  }

  # Conditionally allow PUT/DELETE for writer roles
  dynamic "statement" {
    for_each = length(var.writer_role_arns) > 0 ? [1] : []
    content {
      sid = "AllowWriteRoles"
      principals {
        type        = "AWS"
        identifiers = var.writer_role_arns
      }
      actions   = ["s3:PutObject", "s3:DeleteObject"]
      resources = ["${aws_s3_bucket.main.arn}/*"]
    }
  }

  # Always deny non-TLS access
  statement {
    sid    = "DenyUnEncrypted"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:*"]
    resources = ["${aws_s3_bucket.main.arn}/*"]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

# Only attach policy if any principals exist
resource "aws_s3_bucket_policy" "main" {
  count  = length(var.reader_role_arns) + length(var.writer_role_arns) > 0 ? 1 : 0
  bucket = aws_s3_bucket.main.id
  policy = data.aws_iam_policy_document.main.json
}
