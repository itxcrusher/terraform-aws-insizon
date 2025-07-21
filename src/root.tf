############################################
# root.tf – orchestrates all modules
############################################
# Conventions:
#   – app_key   = "<app_name>-<env>"
#   – For_each  over locals built in locals.tf
#   – Modules are thin; heavy logic stays in locals
############################################

#################################################
# SNS
#################################################
module "sns_module" {
  for_each = local.sns_map
  source   = "./modules/sns"

  topics = each.value.topics

  providers = {
    aws = aws.sns
  }
}

#################################################
# Static-site bucket upload
#################################################
module "static_s3_upload" {
  for_each = local.static_files_map

  source = "./modules/s3_static_upload"
  cfg    = each.value

  depends_on = [
    aws_s3_bucket.static_shared,
    aws_s3_bucket_public_access_block.static_shared,
    aws_s3_bucket_policy.allow_public
  ]
}

#################################################
# Lambda (HTTP + Cron triggers)
#################################################
module "lambda_event_module" {
  for_each = local.lambda_event_map
  source   = "./modules/lambda_event"

  app_key   = each.key   # "<app>-<env>"
  functions = each.value # list(object)
}

#################################################
# Elastic Beanstalk
#################################################
module "beanstalk_module" {
  for_each = local.beanstalk_map # renamed
  source   = "./modules/beanstalk"

  app_key = each.key
  cfg     = each.value
}

#################################################
# AWS Budgets
#################################################
module "budgets_module" {
  for_each = local.budget_map
  source   = "./modules/budgets"

  app_key = each.key
  cfg     = each.value
}

#################################################
# ECR repositories
#################################################
module "ecr_module" {
  for_each = local.ecr_map
  source   = "./modules/ecr"

  app_key = each.key
  cfg     = each.value
}

#################################################
# IAM  – Users and Roles (global, not per-app)
#################################################
module "iam_users" {
  for_each = local.user_role_map
  source   = "./modules/iam/users"

  user_name               = each.key
  create_console_password = !contains(each.value, "serviceAccount")
  enable_csv_export       = true
}

# Roles are *global*; one module instance is enough
module "iam_roles" {
  source = "./modules/iam/roles"

  role_matrix = local.role_matrix
}

#################################################
# S3 Website + CloudFront
#################################################
module "s3_module" {
  for_each = local.app_map
  source   = "./modules/s3"

  # Core identifiers
  app_key     = each.key
  bucket_name = "${each.key}-bucket-test" # override if you need custom naming

  active_public_keys = local.cf_keys_by_app[each.key]

  public_key_ids = {
    for alias in local.cf_keys_by_app[each.key] :
    alias => aws_cloudfront_public_key.global_keys[alias].id
  }

  key_group_ids = {
    for k, v in aws_cloudfront_key_group.global_key_groups : k => v.id
  }

  # CloudFront wiring
  cloudfront_cfg = {
    key_group_name = local.key_parts[each.key].key_group_name
    key_names      = local.cf_keys_by_app[each.key]
    behavior       = local.cf_behavior_by_app[each.key]
  }

  # IAM access
  reader_role_arns = local.app_role_arns_read[each.key]
  writer_role_arns = local.app_role_arns_write[each.key]

  depends_on = [module.iam_roles]
}

#################################################
# Secrets Manager – consolidate runtime secrets
#################################################
module "secret_manager_module" {
  for_each = local.app_map
  source   = "./modules/secret_manager"

  app_key = each.key

  yaml_file_path = "${path.module}/../private/secret_manager_secrets/${each.key}-secrets-manager.yaml"

  # first serviceAccount creds we found
  iam_access_key_id     = try(local.sa_access_keys[0], "")
  iam_secret_access_key = try(local.sa_secret_keys[0], "")

  # CloudFront + S3 artefacts from s3_module
  cloudfront_key_pair_ids        = module.s3_module[each.key].cloudfront_key_pair_ids
  cloudfront_distribution_domain = module.s3_module[each.key].cloudfront_distribution_domain
  cloudfront_private_key         = file("${path.module}/../private/cloudfront/rsa_keys/private/${local.key_parts[each.key].app_name}-${local.key_parts[each.key].env}-private-key.pem")
  s3_bucket_name                 = module.s3_module[each.key].s3_bucket_name

  depends_on = [
    module.iam_users,
    module.iam_roles,
    module.s3_module
  ]
}

#################################################
# Safety-check: must have at least one serviceAccount
#################################################
check "service_account_present" {
  assert {
    condition     = length(local.sa_access_keys) > 0
    error_message = "No user with role 'serviceAccount' found in user-roles.yaml."
  }
}
