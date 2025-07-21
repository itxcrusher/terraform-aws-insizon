locals {
  # Dynamically resolve path to source directory
  source_dir = abspath("${path.module}/../../../private/${var.cfg.bucket_name}/${var.cfg.app_name}")

  candidate_files = fileset(local.source_dir, "**")

  upload_files = [
    for f in local.candidate_files :
    f if !contains(var.cfg.files_excluded, f)
  ]

  mime_map = {
    html = "text/html"
    css  = "text/css"
    js   = "application/javascript"
    png  = "image/png"
    jpg  = "image/jpeg"
    jpeg = "image/jpeg"
    svg  = "image/svg+xml"
    json = "application/json"
    txt  = "text/plain"
  }
}
