############################################################
# locals.tf – strict, fail-fast config loading
# Files are resolved from: src/config/<env>/*.yaml
# Only var.env is required (set by shell/CI).
############################################################

# Region aliases (used by some modules)
locals {
  US_East1_NorthVirginia = "us-east-1"
  US_East2_Ohio          = "us-east-2"

  # Resolve per-env config dir
  cfg_dir = "${path.module}/config/${var.env}"

  # dynamic private root for env-scoped artifacts
  private_root = "${path.module}/../private/${var.env}"
}

############################################################
# 1) Load YAML (no try/implicit defaults)
#    If a file is missing or a key path is wrong → Terraform fails.
############################################################
locals {
  users_file        = yamldecode(file("${local.cfg_dir}/user-roles.yaml"))
  apps_file         = yamldecode(file("${local.cfg_dir}/apps.yaml"))
  beanstalk_file    = yamldecode(file("${local.cfg_dir}/elasticbeanstalk.yaml"))
  ecr_file          = yamldecode(file("${local.cfg_dir}/ecr.yaml"))
  budget_file       = yamldecode(file("${local.cfg_dir}/budget.yaml"))
  cloudfront_file   = yamldecode(file("${local.cfg_dir}/cloudfront.yaml"))
  lambda_file       = yamldecode(file("${local.cfg_dir}/lambda-event.yaml"))
  static_files_file = yamldecode(file("${local.cfg_dir}/static-files.yaml"))
  sns_file          = yamldecode(file("${local.cfg_dir}/sns.yaml"))

  # Integrated GitHub/AWS (former second project)
  codebuild_file = yamldecode(file("${local.cfg_dir}/codebuild.yaml"))
  kms_file       = yamldecode(file("${local.cfg_dir}/kms.yaml"))
  rds_file       = yamldecode(file("${local.cfg_dir}/rds.yaml"))
  glacier_file   = yamldecode(file("${local.cfg_dir}/glacier.yaml"))
  sms_file       = yamldecode(file("${local.cfg_dir}/sms.yaml"))
}

# Enabled switches (each YAML must have top-level `enabled: true|false`)
locals {
  apps_enabled       = local.apps_file.enabled
  cloudfront_enabled = local.cloudfront_file.enabled
  budgets_enabled    = local.budget_file.enabled
  ecr_enabled        = local.ecr_file.enabled
  beanstalk_enabled  = local.beanstalk_file.enabled
  lambda_enabled     = local.lambda_file.enabled
  static_enabled     = local.static_files_file.enabled
  sns_enabled        = local.sns_file.enabled
  iam_enabled        = local.users_file.enabled

  codebuild_enabled = local.codebuild_file.enabled
  kms_enabled       = local.kms_file.enabled
  rds_enabled       = local.rds_file.enabled
  glacier_enabled   = local.glacier_file.enabled
  sms_enabled       = local.sms_file.enabled
}

# Extract nested blocks (explode loudly if keys aren’t present)
locals {
  raw_users             = local.users_file.users
  raw_apps              = local.apps_file.apps
  beanstalk_cfg_raw     = local.beanstalk_file.beanstalk
  ecr_cfg_raw           = local.ecr_file.ecr
  budget_cfg_raw        = local.budget_file.budgets
  cloudfront_cfg_raw    = local.cloudfront_file.cloudfront_key_groups
  lambda_events_cfg_raw = local.lambda_file.lambda_events
  static_files_cfg_raw  = local.static_files_file.static_files
  sns_cfg_raw           = local.sns_file.sns

  codebuild_cfg = local.codebuild_file.codebuild
  backend_cfg   = local.codebuild_file.backend
  kms_cfg       = local.kms_file.kms
  rds_cfg       = local.rds_file.rds
  glacier_cfg   = local.glacier_file.glacier
  sms_cfg       = local.sms_file.sms
}

############################################################
# 2) Validation helpers (hard fail with clear messages)
#    Validate ONLY when the corresponding file is enabled.
############################################################

# Apps minimal shape
check "apps_keys" {
  assert {
    condition = !local.apps_enabled || (
      can(local.apps_file.apps) &&
      length(local.apps_file.apps) >= 1 &&
      alltrue([
        for a in local.raw_apps :
        can(a.app_name) && can(a.key_group_name)
      ])
    )
    error_message = "apps.yaml enabled=true but 'apps' missing/empty or an item lacks 'app_name'/'key_group_name'."
  }
}

# CloudFront groups must include all required properties
check "cloudfront_keys" {
  assert {
    condition = !local.cloudfront_enabled || (
      can(local.cloudfront_file.cloudfront_key_groups) &&
      alltrue([
        for g in local.cloudfront_cfg_raw :
        can(g.key_group_name) &&
        can(g.keys) && length(g.keys) <= 100 &&
        can(g.default_root_object) &&
        can(g.price_class) &&
        can(g.viewer_protocol_policy) &&
        can(g.allowed_methods) &&
        can(g.cached_methods) &&
        can(g.geo_restriction.restriction_type) &&
        can(g.geo_restriction.locations)
      ])
    )
    error_message = "cloudfront.yaml enabled=true but required fields missing in one or more key groups."
  }
}

# Static files
check "static_files_keys" {
  assert {
    condition = !local.static_enabled || (
      can(local.static_files_cfg_raw.static_folder_name) &&
      can(local.static_files_cfg_raw.apps)
    )
    error_message = "static-files.yaml enabled=true but missing 'static_files.static_folder_name' or 'static_files.apps'."
  }
}

# IAM users
check "users_keys" {
  assert {
    condition = !local.iam_enabled || (
      can(local.users_file.users) &&
      length(local.users_file.users) > 0
    )
    error_message = "user-roles.yaml enabled=true but 'users' missing/empty."
  }
}

# SNS HTTP collections
check "sns_keys" {
  assert {
    condition     = !local.sns_enabled || can(local.sns_file.sns)
    error_message = "sns.yaml enabled=true but 'sns' map missing."
  }
}

# Budgets
check "budget_keys" {
  assert {
    condition     = !local.budgets_enabled || can(local.budget_file.budgets)
    error_message = "budget.yaml enabled=true but 'budgets' list missing."
  }
}

# Optional stacks with enabled flag + required keys when enabled
check "codebuild_keys" {
  assert {
    condition = !local.codebuild_enabled || (
      can(local.codebuild_cfg.name_prefix) &&
      can(local.codebuild_cfg.repo_url) &&
      can(local.codebuild_cfg.buildspec_path) &&
      can(local.codebuild_cfg.compute_type) &&
      can(local.codebuild_cfg.image) &&
      can(local.codebuild_cfg.github_token_param) &&
      can(local.codebuild_cfg.github_branch) &&
      can(local.backend_cfg.bucket) &&
      can(local.backend_cfg.dynamodb_table)
    )
    error_message = "codebuild.yaml enabled=true but required fields missing (codebuild.* and backend.*)."
  }
}

check "kms_keys" {
  assert {
    condition = !local.kms_enabled || (
      can(local.kms_cfg.alias_name) &&
      can(local.kms_cfg.rotation_days)
    )
    error_message = "kms.yaml enabled=true but 'kms.alias_name' or 'kms.rotation_days' missing."
  }
}

check "rds_keys" {
  assert {
    condition = !local.rds_enabled || (
      can(local.rds_cfg.engine_version) &&
      can(local.rds_cfg.sizing.instance_class) &&
      can(local.rds_cfg.sizing.multi_az) &&
      can(local.rds_cfg.sizing.allocated_storage) &&
      can(local.rds_cfg.sizing.backup_retention) &&
      can(local.rds_cfg.vpc_id) &&
      can(local.rds_cfg.subnet_ids) && length(local.rds_cfg.subnet_ids) >= 2 &&
      can(local.rds_cfg.sg_ids) && length(local.rds_cfg.sg_ids) >= 1 &&
      can(local.rds_cfg.db_name) &&
      can(local.rds_cfg.username_ssm) &&
      can(local.rds_cfg.password_ssm)
    )
    error_message = "rds.yaml enabled=true but required fields missing (engine/sizing/network/db identity/SSM params)."
  }
}

check "glacier_keys" {
  assert {
    condition     = !local.glacier_enabled || can(local.glacier_cfg.rules)
    error_message = "glacier.yaml enabled=true but 'glacier.rules' missing."
  }
}

check "sms_keys" {
  assert {
    condition     = !local.sms_enabled || can(local.sms_cfg.preferences)
    error_message = "sms.yaml enabled=true but 'sms.preferences' missing."
  }
}

# Dependency sanity: S3+CloudFront stack requires IAM and CloudFront when apps are enabled
check "apps_require_cf_and_iam" {
  assert {
    condition     = !local.apps_enabled || (local.cloudfront_enabled && local.iam_enabled)
    error_message = "apps.yaml enabled=true requires cloudfront.yaml and user-roles.yaml also enabled."
  }
}

############################################################
# 3) Master app key map: app_key = "<app_name>-<env>"
############################################################
locals {
  app_map = local.apps_enabled ? {
    for app in local.raw_apps :
    "${app.app_name}-${var.env}" => app
  } : {}

  key_parts = {
    for k, v in local.app_map :
    k => {
      app_name       = v.app_name
      env            = var.env
      key_group_name = v.key_group_name
    }
  }
}

############################################################
# 4) CloudFront lookups (only when CloudFront enabled)
############################################################
locals {
  cf_group_map = local.cloudfront_enabled ? {
    for g in local.cloudfront_cfg_raw :
    g.key_group_name => {
      keys                   = g.keys
      default_root_object    = g.default_root_object
      price_class            = g.price_class
      viewer_protocol_policy = g.viewer_protocol_policy
      allowed_methods        = g.allowed_methods
      cached_methods         = g.cached_methods
      geo_restriction        = g.geo_restriction
    }
  } : {}

  cf_keys_by_app = (local.apps_enabled && local.cloudfront_enabled) ? {
    for k, kp in local.key_parts :
    k => local.cf_group_map[kp.key_group_name].keys
  } : {}

  cf_behavior_by_app = (local.apps_enabled && local.cloudfront_enabled) ? {
    for k, kp in local.key_parts :
    k => {
      default_root_object    = local.cf_group_map[kp.key_group_name].default_root_object
      price_class            = local.cf_group_map[kp.key_group_name].price_class
      viewer_protocol_policy = local.cf_group_map[kp.key_group_name].viewer_protocol_policy
      allowed_methods        = local.cf_group_map[kp.key_group_name].allowed_methods
      cached_methods         = local.cf_group_map[kp.key_group_name].cached_methods
      geo_restriction        = local.cf_group_map[kp.key_group_name].geo_restriction
    }
  } : {}

  valid_app_keys = [for app in local.raw_apps : "${app.app_name}-${var.env}"]

  active_public_keys = (local.apps_enabled && local.cloudfront_enabled) ? distinct(flatten([for app in local.raw_apps : local.cf_group_map[app.key_group_name].keys])) : []
}

# Preferred CloudFront signing alias per app:
# - If the app-specific alias "<app>-<env>" is in the group's keys, use it
# - Else fall back to the first key in that group (still valid)
locals {
  selected_cf_alias_by_app = (local.apps_enabled && local.cloudfront_enabled) ? {
    for k, kp in local.key_parts :
    k => (
      contains(local.cf_keys_by_app[k], "${kp.app_name}-${kp.env}")
      ? "${kp.app_name}-${kp.env}"
      : local.cf_keys_by_app[k][0]
    )
  } : {}
}

# Fail if the app’s alias isn’t in its key group
locals {
  missing_app_aliases = (local.apps_enabled && local.cloudfront_enabled) ? [
    for k, kp in local.key_parts :
    k if !contains(local.cf_keys_by_app[k], "${kp.app_name}-${kp.env}")
  ] : []
}

# This check currently requires every app to have its own <app>-dev key in the cloudfront key group
# check "cf_group_has_app_alias" {
#   assert {
#     condition     = length(local.missing_app_aliases) == 0
#     error_message = "CloudFront key group missing app-specific alias for: ${join(", ", local.missing_app_aliases)}"
#   }
# }

############################################################
# 5) Normalised service maps (budget/ecr/beanstalk/lambda/static/sns)
############################################################
locals {
  budget_map = local.budgets_enabled ? {
    for b in local.budget_cfg_raw :
    "${b.app_name}-${var.env}" => b
  } : {}

  ecr_map = local.ecr_enabled ? {
    for e in local.ecr_cfg_raw :
    "${e.app_name}-${var.env}" => e
    if can(e.create_service) && e.create_service
  } : {}

  beanstalk_map = local.beanstalk_enabled ? {
    for b in local.beanstalk_cfg_raw :
    "${b.app_name}-${var.env}" => b
    if can(b.create_service) && b.create_service
  } : {}

  lambda_event_map = local.lambda_enabled ? {
    for l in local.lambda_events_cfg_raw :
    "${l.app_name}-${var.env}" => [l]
    if can(l.create_service) && l.create_service
  } : {}

  static_files_bucket_name = "${local.static_files_cfg_raw.static_folder_name}-${var.env}"
  static_files_apps_raw    = local.static_files_cfg_raw.apps

  static_files_map = local.static_enabled ? {
    for app in local.static_files_apps_raw :
    app.app_name => merge(app, { bucket_name = local.static_files_bucket_name })
  } : {}

  sns_map = local.sns_enabled ? {
    for collection, config in local.sns_cfg_raw :
    collection => {
      topics = {
        for topic_name, topic_cfg in config.topics :
        topic_name => {
          name      = topic_cfg.name
          endpoint  = topic_cfg.endpoint
          protocols = topic_cfg.protocols
        }
      }
    }
  } : {}
}

############################################################
# 6) IAM plumbing (limits list plain app names; we add -<env>)
############################################################
locals {
  user_role_map   = local.iam_enabled ? { for u in local.raw_users : u.userName => u.roles } : {}
  user_limits_raw = local.iam_enabled ? { for u in local.raw_users : u.userName => (can(u.limit) ? u.limit : null) } : {}

  user_limits_env = local.iam_enabled ? {
    for u, lim in local.user_limits_raw :
    u => lim == null ? null : [for name in lim : "${name}-${var.env}"]
  } : {}

  role_types = {
    admin          = "privileged"
    developer      = "privileged"
    serviceAccount = "privileged"
    readOnly       = "readonly"
  }

  role_matrix = local.iam_enabled ? {
    for role in keys(local.role_types) :
    role => {
      base_actions  = role == "admin" ? ["*"] : role == "readOnly" ? ["s3:Get*", "cloudfront:Get*", "ses:Get*", "secretsmanager:GetSecretValue"] : ["s3:*", "cloudfront:*", "ses:*", "secretsmanager:*"]
      extra_actions = lookup(var.extra_role_actions, role, [])
      principal_arns = [
        for u, m in module.iam_users : m.arn
        if contains(local.user_role_map[u], role)
      ]
      type = local.role_types[role]
    }
    if length([
      for u, m in module.iam_users : m.arn
      if contains(local.user_role_map[u], role)
    ]) > 0
  } : {}

  app_roles_map = (local.apps_enabled && local.iam_enabled) ? {
    for app_key in keys(local.app_map) :
    app_key => distinct(flatten([
      for user, roles in local.user_role_map :
      local.user_limits_env[user] == null || contains(local.user_limits_env[user], app_key)
      ? roles : []
    ]))
  } : {}

  # Reader ARNs by app
  app_role_arns_read = (local.apps_enabled && local.iam_enabled) ? {
    for app_key, roles in local.app_roles_map :
    app_key => [
      for r in roles :
      module.iam_roles["global"].role_arns[r]
      if local.role_types[r] == "readonly"
    ]
  } : {}

  # Writer ARNs by app
  app_role_arns_write = (local.apps_enabled && local.iam_enabled) ? {
    for app_key, roles in local.app_roles_map :
    app_key => [
      for r in roles :
      module.iam_roles["global"].role_arns[r]
      if local.role_types[r] == "privileged"
    ]
  } : {}
}

############################################################
# 7) Helper – first serviceAccount creds (for secrets module)
############################################################
locals {
  sa_access_keys = local.iam_enabled ? [
    for u, rs in local.user_role_map :
    module.iam_users[u].access_key_id
    if contains(rs, "serviceAccount")
  ] : []

  sa_secret_keys = local.iam_enabled ? [
    for u, rs in local.user_role_map :
    module.iam_users[u].secret_access_key
    if contains(rs, "serviceAccount")
  ] : []
}

############################################################
# Shared static bucket (public website style)
# Created unconditionally (shared across apps).
############################################################
# Shared static bucket (public website style)
resource "aws_s3_bucket" "static_shared" {
  count  = local.static_enabled ? 1 : 0
  bucket = local.static_files_bucket_name
}

resource "aws_s3_bucket_public_access_block" "static_shared" {
  count                   = local.static_enabled ? 1 : 0
  bucket                  = aws_s3_bucket.static_shared[0].id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "allow_public" {
  count  = local.static_enabled ? 1 : 0
  bucket = aws_s3_bucket.static_shared[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicRead"
      Effect    = "Allow"
      Principal = "*"
      Action    = ["s3:GetObject"]
      Resource  = "${aws_s3_bucket.static_shared[0].arn}/*"
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.static_shared]
}

############################################################
# CloudFront keys & key groups (created only if CF/apps enabled)
############################################################
resource "aws_cloudfront_public_key" "global_keys" {
  for_each = toset(local.active_public_keys)

  name        = "${each.key}-public-key"
  encoded_key = file("${local.private_root}/cloudfront/rsa_keys/public/${each.key}-public-key.pem")
  comment     = "Global CloudFront Public Key: ${each.key}"

  lifecycle {
    ignore_changes = [encoded_key]
  }
}

resource "aws_cloudfront_key_group" "global_key_groups" {
  for_each = local.cf_group_map

  name = each.key
  items = [
    for key in each.value.keys :
    aws_cloudfront_public_key.global_keys[key].id
  ]

  comment = "CloudFront KeyGroup for ${each.key}"
}

############################################################
# CI/Tagging helpers
############################################################
data "aws_caller_identity" "current" {}

locals {
  tags = {
    environment = var.env
    managed_by  = "terraform"
    project     = "insizon"
  }
  # do not need apply env flag now
  # ci_apply_flag = local.codebuild_enabled && contains(local.codebuild_cfg.apply_envs, var.env)
}

# Only demand a service account if IAM is enabled
check "service_account_present" {
  assert {
    condition     = !local.iam_enabled || length(local.sa_access_keys) > 0
    error_message = "user-roles.yaml enabled=true but no user with role 'serviceAccount' found."
  }
}

############################################################
# IAM credentials CSV export
############################################################
# File layout: private/insizonxcontractor-<env>-bucket/iam_access_keys/<user>-keys.csv
resource "local_file" "iam_creds_csv" {
  for_each = local.iam_enabled && var.export_iam_credentials_csv ? module.iam_users : {}

  filename = "${local.private_root}/iam_access_keys/${each.key}-keys.csv"
  content = join("\n", [
    "access_key,secret_key,console_password",
    format("%s,%s,%s",
      module.iam_users[each.key].access_key_id,
      module.iam_users[each.key].secret_access_key,
      coalesce(module.iam_users[each.key].console_password, "N/A")
    )
  ])
}

############################################################
# CloudFront CSV per app export
############################################################
# One CSV per app with CloudFront: KeyPairId, Distribution, Bucket
# File: private/.../cloudfront/id/<app>-KeyPair-n-DistributionSubdomain.csv
resource "local_file" "cloudfront_csv" {
  # Only for apps that actually built S3+CF
  for_each = (local.apps_enabled && local.cloudfront_enabled && local.iam_enabled) ? module.s3_module : {}

  filename = "${local.private_root}/cloudfront/id/${each.key}-KeyPair-n-DistributionSubdomain.csv"

  content = join("\n",
    concat(
      ["Aws_CloudFront_KeyPairId,Aws_Cloudfront_DistributionSubdomain,S3_Bucket"],
      [
        for alias in local.cf_keys_by_app[each.key] :
        format(
          "%s,%s,%s",
          try(module.s3_module[each.key].cloudfront_key_pair_ids[alias], ""),
          module.s3_module[each.key].cloudfront_distribution_domain,
          module.s3_module[each.key].s3_bucket_name
        )
        if contains(keys(module.s3_module[each.key].cloudfront_key_pair_ids), alias)
      ]
    )
  )
}
