############################################################
# secret_manager – locals.tf
############################################################
# 1.  Read the per-app YAML secrets file.
# 2.  Merge runtime AWS credentials + CloudFront data.
# 3.  Result is written as a single JSON blob.

locals {
  ##########################################################
  # Parse YAML (expects top-level `secrets:` list)
  ##########################################################
  decoded = var.yaml_file_path != "" ? yamldecode(file(var.yaml_file_path)) : { secrets = [] }

  # Convert `[ { key = "DB_PASS", value = "abc" }, … ]` → map
  secrets_map = { for item in local.decoded.secrets : item.key => item.value }

  ##########################################################
  # Runtime-generated additions
  ##########################################################
  runtime_map = {
    AWS_IAM_SERVICE_USER_ACCESS_KEY_ID     = var.iam_access_key_id
    AWS_IAM_SERVICE_USER_SECRET_ACCESS_KEY = var.iam_secret_access_key
    AWS_CLOUDFRONT_KEY_PAIR_ID            = try(var.cloudfront_key_pair_ids[var.app_key], "")
    AWS_CLOUDFRONT_DOMAIN                  = var.cloudfront_distribution_domain
    AWS_CLOUDFRONT_PRIVATE_KEY             = var.cloudfront_private_key
    S3_BUCKET_NAME                         = var.s3_bucket_name
  }

  ##########################################################
  # Final payload
  ##########################################################
  final_secrets = merge(local.secrets_map, local.runtime_map)

  # Flatten secrets to string:string map (for UI compatibility)
  flat_map_for_ui = {
    for k, v in local.final_secrets :
    k => tostring(v)
    if can(tostring(v)) && !can(length(keys(v))) # exclude maps/lists
  }

  # Optional – keep both if you want structured secrets too
  full_json_blob = local.final_secrets
}
