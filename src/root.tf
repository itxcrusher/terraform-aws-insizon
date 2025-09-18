############################################
# root.tf – orchestrates all modules
# Only input: var.env (dev|qa|prod)
############################################

#################################################
# SNS (HTTP/HTTPS subscriptions) – us-east-1 provider
#################################################
module "sns_module" {
  for_each = local.sns_map
  source   = "./modules/sns"

  topics = each.value.topics

  providers = { aws = aws.sns }
}

#################################################
# Static-site bucket upload
#################################################
module "static_s3_upload" {
  for_each = local.static_files_map
  source   = "./modules/s3_static_upload"

  cfg        = each.value
  source_dir = "${local.private_root}/${local.static_files_cfg_raw.static_folder_name}/${each.value.app_name}"
}

#################################################
# Lambda (HTTP + Cron triggers)
#################################################
module "lambda_event_module" {
  for_each = local.lambda_event_map
  source   = "./modules/lambda_event"

  app_key   = each.key   # "<app>-<env>"
  functions = each.value # list(object)

  # Build artifact map: { function_name => "/abs/or/rel/path/to/zip" }
  artifacts = {
    for f in each.value :
    f.function_name => "${local.private_root}/lambda/${each.key}/${f.function_name}.zip"
  }
}

#################################################
# Elastic Beanstalk
#################################################
module "beanstalk_module" {
  for_each = local.beanstalk_map
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
# IAM – Users and Roles (global)
#################################################
module "iam_users" {
  for_each = local.iam_enabled ? local.user_role_map : {}
  source   = "./modules/iam/users"

  user_name               = each.key
  create_console_password = !contains(each.value, "serviceAccount")
}

module "iam_roles" {
  for_each = local.iam_enabled ? { global = true } : {}
  source   = "./modules/iam/roles"

  role_matrix = local.role_matrix
  env         = var.env
  name_prefix = "" # optional: "insizon-"
  tags        = local.tags
}

#################################################
# S3 Website + CloudFront
#################################################
module "s3_module" {
  for_each = (local.apps_enabled && local.cloudfront_enabled && local.iam_enabled) ? local.app_map : {}
  source   = "./modules/s3"

  app_key     = each.key
  bucket_name = "${each.key}-bucket"

  active_public_keys = local.cf_keys_by_app[each.key]

  public_key_ids = {
    for alias in local.cf_keys_by_app[each.key] :
    alias => aws_cloudfront_public_key.global_keys[alias].id
  }

  key_group_ids = {
    for k, v in aws_cloudfront_key_group.global_key_groups : k => v.id
  }

  cloudfront_cfg = {
    key_group_name = local.key_parts[each.key].key_group_name
    key_names      = local.cf_keys_by_app[each.key]
    behavior       = local.cf_behavior_by_app[each.key]
  }

  reader_role_arns = local.app_role_arns_read[each.key]
  writer_role_arns = local.app_role_arns_write[each.key]

  enable_bucket_encryption = false
  enable_versioning        = false

  depends_on = [module.iam_roles]
}

#################################################
# Secrets Manager – consolidate runtime secrets
#################################################
module "secret_manager_module" {
  for_each = (local.apps_enabled && local.iam_enabled) ? local.app_map : {}
  source   = "./modules/secret_manager"

  app_key = each.key

  yaml_file_path = "${local.private_root}/secret_manager_secrets/${each.key}-secrets-manager.yaml"

  # runtime from IAM and S3/CF
  iam_access_key_id     = local.sa_access_keys[0]
  iam_secret_access_key = local.sa_secret_keys[0]

  cloudfront_key_pair_ids        = module.s3_module[each.key].cloudfront_key_pair_ids
  cloudfront_distribution_domain = module.s3_module[each.key].cloudfront_distribution_domain
  cloudfront_private_key         = file("${local.private_root}/cloudfront/rsa_keys/private/${local.selected_cf_alias_by_app[each.key]}-private-key.pem")
  s3_bucket_name                 = module.s3_module[each.key].s3_bucket_name

  cloudfront_key_alias = local.selected_cf_alias_by_app[each.key]

  depends_on = [module.iam_users, module.iam_roles, module.s3_module]
}

#################################################
# Integrated GitHub/AWS stacks (strict enabled flags)
#################################################

# CodeBuild CI project
module "codebuild" {
  source = "./modules/codebuild"
  count  = local.codebuild_enabled ? 1 : 0

  account_id   = data.aws_caller_identity.current.account_id
  name_prefix  = local.codebuild_cfg.name_prefix
  env          = var.env
  project_name = "${local.codebuild_cfg.name_prefix}-${var.env}"

  # Source & buildspec
  repo_url       = local.codebuild_cfg.repo_url
  buildspec_path = local.codebuild_cfg.buildspec_path

  # Remote state for CI runners
  backend_bucket          = local.backend_cfg.bucket
  backend_lock_table_name = local.backend_cfg.dynamodb_table

  # GitHub integration (PAT lives in SSM; module fetches it by param name)
  github_token_param = local.codebuild_cfg.github_token_param
  github_branch      = local.codebuild_cfg.github_branch

  # Build environment
  region       = local.US_East2_Ohio
  compute_type = local.codebuild_cfg.compute_type
  image        = local.codebuild_cfg.image

  tags = local.tags
}

# Glacier lifecycle
module "glacier" {
  source = "./modules/glacier"
  count  = local.glacier_enabled ? 1 : 0

  rules = local.glacier_cfg.rules
  tags  = local.tags
}

# SMS (SNS account prefs + topics; us-east-1)
module "sms" {
  source = "./modules/sms"
  count  = local.sms_enabled ? 1 : 0

  preferences = local.sms_cfg.preferences
  topics      = can(local.sms_cfg.topics) ? local.sms_cfg.topics : []
  pinpoint    = can(local.sms_cfg.pinpoint) ? local.sms_cfg.pinpoint : { enable = false }

  providers = { aws = aws.sns }
  tags      = local.tags
}

# KMS CMK + alias
module "kms" {
  source = "./modules/kms"
  count  = local.kms_enabled ? 1 : 0

  alias_name    = local.kms_cfg.alias_name
  rotation_days = local.kms_cfg.rotation_days
  tags          = local.tags
}

# RDS Postgres
module "rds" {
  source = "./modules/rds"
  count  = local.rds_enabled ? 1 : 0

  engine_version    = local.rds_cfg.engine_version
  instance_class    = local.rds_cfg.sizing.instance_class
  multi_az          = local.rds_cfg.sizing.multi_az
  allocated_storage = local.rds_cfg.sizing.allocated_storage
  backup_retention  = local.rds_cfg.sizing.backup_retention

  vpc_id     = local.rds_cfg.vpc_id
  subnet_ids = local.rds_cfg.subnet_ids
  sg_ids     = local.rds_cfg.sg_ids

  db_name      = local.rds_cfg.db_name
  username_ssm = local.rds_cfg.username_ssm
  password_ssm = local.rds_cfg.password_ssm

  tags = local.tags
}
