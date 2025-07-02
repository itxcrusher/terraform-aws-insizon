###############################################
# S3 Static Upload – locals.tf
# Derives paths & file lists from app_key + cfg
###############################################

# Split "<app_name>-<env>" where env is last segment
locals {
  app_parts = split("-", var.app_key)
  env       = local.app_parts[length(local.app_parts) - 1]
  app_name  = join("-", slice(local.app_parts, 0, length(local.app_parts) - 1))

  ########################################
  # Source directory resolution
  ########################################
  #   private/static_bucket/<app>-<env>/<folder_name>
  ########################################
  base_dir   = "${path.module}/../../../private/static_bucket/${local.app_name}-${local.env}"
  folder     = coalesce(var.cfg.folder_name, "public")
  source_dir = abspath("${local.base_dir}/${local.folder}")

  ########################################
  # File discovery
  ########################################
  candidate_files = fileset(local.source_dir, "**")

  upload_files = [
    for f in local.candidate_files :
    f if !contains(var.cfg.files_excluded, f)
  ]

  ########################################
  # Minimal MIME map (extend as needed)
  ########################################
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
