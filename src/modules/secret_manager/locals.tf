############################################################
# secret_manager – locals.tf
############################################################
# 1.  Read the per-app YAML secrets file.
# 2.  Merge runtime AWS credentials + CloudFront data.
# 3.  Result is written as a single JSON blob.

# Parse YAML (optional, but must be a list under `secrets:`)
locals {
  decoded = var.yaml_file_path != "" ? yamldecode(file(var.yaml_file_path)) : { secrets = [] }

  # Convert to map
  secrets_map = {
    for item in local.decoded.secrets :
    item.key => item.value
  }

  # Keys Terraform owns (YAML must not override these)
  reserved_keys = [
    # remove service account keys from all secrets
    # "AWS_IAM_SERVICE_USER_ACCESS_KEY_ID",
    # "AWS_IAM_SERVICE_USER_SECRET_ACCESS_KEY",
    "AWS_CLOUDFRONT_KEY_PAIR_ID",
    "AWS_CLOUDFRONT_DOMAIN",
    "AWS_CLOUDFRONT_PRIVATE_KEY",
    "S3_BUCKET_NAME",
  ]

  yaml_keys = keys(local.secrets_map)
}

# Fail fast if YAML tries to set reserved keys
check "no_reserved_keys_in_yaml" {
  assert {
    condition     = length(setintersection(local.reserved_keys, local.yaml_keys)) == 0
    error_message = "Secrets YAML contains reserved keys set at runtime. Remove: ${join(", ", setintersection(local.reserved_keys, local.yaml_keys))}"
  }
}

# Runtime-derived values
locals {
  runtime_map = {
    # remove service account keys from all secrets
    # AWS_IAM_SERVICE_USER_ACCESS_KEY_ID     = var.iam_access_key_id
    # AWS_IAM_SERVICE_USER_SECRET_ACCESS_KEY = var.iam_secret_access_key

    # resolve by alias, not app_key
    AWS_CLOUDFRONT_KEY_PAIR_ID = try(var.cloudfront_key_pair_ids[var.cloudfront_key_alias], "")

    AWS_CLOUDFRONT_DOMAIN      = var.cloudfront_distribution_domain
    AWS_CLOUDFRONT_PRIVATE_KEY = var.cloudfront_private_key
    S3_BUCKET_NAME             = var.s3_bucket_name
  }

  # We want runtime to win.
  # But since we blocked reserved keys in YAML already, order is now moot.
  final_secrets = merge(local.secrets_map, local.runtime_map)

  # Optional: a flat map for easy UI readers
  flat_map_for_ui = {
    for k, v in local.final_secrets : k => tostring(v)
    if can(tostring(v)) && !can(length(keys(v)))
  }

  full_json_blob = local.final_secrets
}

# “does the YAML exist?” guard
check "yaml_exists_when_path_provided" {
  assert {
    condition     = var.yaml_file_path == "" || fileexists(var.yaml_file_path)
    error_message = "Secrets YAML not found at ${var.yaml_file_path}"
  }
}

check "alias_has_keypair_id" {
  assert {
    condition     = contains(keys(var.cloudfront_key_pair_ids), var.cloudfront_key_alias)
    error_message = "CloudFront alias '${var.cloudfront_key_alias}' has no KeyPairId for ${var.app_key}."
  }
}
