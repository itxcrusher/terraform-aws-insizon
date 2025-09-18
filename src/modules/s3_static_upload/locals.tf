locals {
  # Gather files under source_dir (tolerate empty/missing dir → upload nothing)
  candidate_files = try(fileset(var.source_dir, "**"), [])

  # Filter out excluded basenames (not globs; keep it simple and explicit)
  excluded_names = toset(try(var.cfg.files_excluded, []))

  upload_files = [
    for rel in local.candidate_files : rel
    if !contains(local.excluded_names, regex("[^/]+$", rel))
  ]

  # Minimal content-type map (fallback to octet-stream)
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
    ico  = "image/x-icon"
  }
}
