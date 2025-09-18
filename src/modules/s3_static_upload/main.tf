###############################################
# Upload static files to <bucket>/<app_name>/...
###############################################

resource "aws_s3_object" "static_files" {
  for_each = { for f in local.upload_files : f => f }

  bucket = var.cfg.bucket_name
  key    = "${var.cfg.app_name}/${each.key}"

  source = "${var.source_dir}/${each.key}"
  etag   = filemd5("${var.source_dir}/${each.key}")

  content_type = lookup(
    local.mime_map,
    lower(regex("[^.]+$", each.key)),
    "binary/octet-stream"
  )
}
