###############################################################################
# modules/s3/main.tf
#
# Creates:
#   • Private S3 bucket (versioning/encryption optional)
#   • (If enabled) a CloudFront distribution via child module that uses OAC
#   • Bucket policy granting:
#       – CloudFront (service principal) READ via OAC (AWS:SourceArn == distribution ARN)
#       – reader_role_arns READ (optional)
#       – writer_role_arns PUT/DELETE (optional)
#       – TLS-only access
#
# IMPORTANT:
#   - We do NOT create/allow an OAI here. Distribution uses OAC.
#   - Do not mix OAI and OAC. Pick OAC (modern & recommended).
###############################################################################

############################
# 1) Bucket core
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
# 2) Versioning & Encryption
############################
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = local.versioning_status
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
# 3) Bucket policy (OAC + roles + TLS)
############################
# NOTE:
# - We dynamically add the OAC statement only when CloudFront is enabled.
# - The OAC statement grants s3:GetObject to CloudFront service principal
#   constrained by AWS:SourceArn == CF distribution ARN.
data "aws_iam_policy_document" "main" {
  # Allow CloudFront READ via OAC (only when CloudFront is enabled)
  dynamic "statement" {
    for_each = local.use_cloudfront ? [1] : []
    content {
      sid    = "AllowCloudFrontReadViaOAC"
      effect = "Allow"

      principals {
        type        = "Service"
        identifiers = ["cloudfront.amazonaws.com"]
      }

      actions   = ["s3:GetObject"]
      resources = ["${aws_s3_bucket.main.arn}/*"]

      # The child cloudfront module must expose distribution_arn
      condition {
        test     = "StringEquals"
        variable = "AWS:SourceArn"
        values   = [module.cloudfront[0].distribution_arn]
      }
    }
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

# Attach the policy if CloudFront is used OR any role ARNs are provided
resource "aws_s3_bucket_policy" "main" {
  count  = (local.use_cloudfront || length(var.reader_role_arns) + length(var.writer_role_arns) > 0) ? 1 : 0
  bucket = aws_s3_bucket.main.id
  policy = data.aws_iam_policy_document.main.json
  # lifecycle {
  #   replace_triggered_by = local.use_cloudfront ? [
  #     module.cloudfront[0].distribution_arn
  #   ] : []
  # }
  # And in practice, depending on the CF module prevents “empty SourceArn” edge cases
  # depends_on = local.use_cloudfront ? [module.cloudfront] : []
}
