###############################################
# Upload static files to shared S3 bucket under app_key subfolder
###############################################

resource "aws_s3_object" "static_files" {
  for_each = { for f in local.upload_files : f => f }

  bucket = var.cfg.bucket_name
  key    = "${var.cfg.app_name}/${each.key}"

  source = "${local.source_dir}/${each.key}"
  etag   = filemd5("${local.source_dir}/${each.key}")

  content_type = lookup(
    local.mime_map,
    lower(regex("[^.]+$", each.key)),
    "binary/octet-stream"
  )
}
