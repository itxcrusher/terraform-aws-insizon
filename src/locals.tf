############################################################
#  locals.tf – single source of truth for all inputs #
############################################################
# Every heavy transform lives here; modules stay dumb.

############################################################
# 1. Load & raw-parse external YAML
############################################################
locals {
  raw_users             = yamldecode(file(var.user_roles_yaml)).users
  raw_apps              = yamldecode(file(var.apps_yaml)).apps
  beanstalk_cfg_raw     = yamldecode(file(var.beanstalk_yaml)).beanstalk
  ecr_cfg_raw           = yamldecode(file(var.ecr_yaml)).ecr
  budget_cfg_raw        = yamldecode(file(var.budget_yaml)).budgets
  cloudfront_cfg_raw    = yamldecode(file(var.cloudfront_yaml)).cloudfront_key_groups
  lambda_events_cfg_raw = yamldecode(file(var.lambda_yaml)).lambda_events
  static_files_cfg_raw  = yamldecode(file(var.static_files_yaml))
  sns_cfg_raw           = yamldecode(file(var.sns_yaml)).sns
}

############################################################
# 2. Fast-fail validation helpers
############################################################
locals {
  _validate_apps = [
    for a in local.raw_apps :
    can(a.app_name) && can(a.env) && can(a.key_group_name)
    ? true
    : error("apps.yaml entry missing required keys: ${jsonencode(a)}")
  ]

  _validate_cf = [
    for g in local.cloudfront_cfg_raw :
    length(g.keys) <= 100
    ? true
    : error("CloudFront key_group '${g.key_group_name}' > 100 keys (hard AWS limit)")
  ]
}

############################################################
# 3. Master app key → object
#    app_key format = "<app_name>-<env>"
############################################################
locals {
  app_map = {
    for app in local.raw_apps :
    "${app.app_name}-${app.env}" => app
    if var.env_filter == "" || app.env == var.env_filter
  }

  key_parts = {
    for k, v in local.app_map :
    k => {
      app_name       = v.app_name
      env            = v.env
      key_group_name = v.key_group_name
    }
  }
}

############################################################
# 4. CloudFront: group_name → object, and helper look-ups
############################################################
# locals {
#   cf_group_map = {
#     for g in local.cloudfront_cfg_raw :
#     g.key_group_name => g
#   }

locals {
  cf_group_map = {
    for g in local.cloudfront_cfg_raw :
    g.key_group_name => {
      keys                   = g.keys
      default_root_object    = try(g.default_root_object, "index.html")
      price_class            = try(g.price_class, "PriceClass_100")
      viewer_protocol_policy = try(g.viewer_protocol_policy, "redirect-to-https")
      allowed_methods        = try(g.allowed_methods, ["GET", "HEAD", "OPTIONS"])
      cached_methods         = try(g.cached_methods, ["GET", "HEAD"])
      geo_restriction = {
        restriction_type = try(g.geo_restriction.restriction_type, "none")
        locations        = try(g.geo_restriction.locations, [])
      }
    }
  }

  cf_keys_by_app = {
    for k, kp in local.key_parts :
    k => local.cf_group_map[kp.key_group_name].keys
  }

  cf_behavior_by_app = {
    for k, kp in local.key_parts :
    k => {
      default_root_object    = local.cf_group_map[kp.key_group_name].default_root_object
      price_class            = local.cf_group_map[kp.key_group_name].price_class
      viewer_protocol_policy = local.cf_group_map[kp.key_group_name].viewer_protocol_policy
      allowed_methods        = local.cf_group_map[kp.key_group_name].allowed_methods
      cached_methods         = local.cf_group_map[kp.key_group_name].cached_methods
      geo_restriction        = local.cf_group_map[kp.key_group_name].geo_restriction
    }
  }
}

locals {
  # List of valid app_keys (like "insizon-app-dev")
  valid_app_keys = [
    for app in local.raw_apps :
    "${app.app_name}-${app.env}"
  ]

  # Flatten all key names *actually needed* by deployed apps
  active_public_keys = distinct(flatten([
    for app in local.raw_apps :
    local.cf_group_map[app.key_group_name].keys
  ]))
}

############################################################
# 5. Normalised service-specific maps (budget, ecr, etc.)
############################################################
locals {
  budget_map = {
    for b in local.budget_cfg_raw :
    "${b.app_name}-${b.env}" => b
  }

  ecr_map = {
    for e in local.ecr_cfg_raw :
    "${e.app_name}-${e.env}" => e
    if e.create_service
  }

  beanstalk_map = {
    for b in local.beanstalk_cfg_raw :
    "${b.app_name}-${b.env}" => b
    if b.create_service
  }

  lambda_event_map = {
    for l in local.lambda_events_cfg_raw :
    "${l.app_name}-${l.env}" => [l]
    if l.create_service
  }

  static_files_bucket_name = local.static_files_cfg_raw.static_files.static_folder_name
  static_files_apps_raw    = local.static_files_cfg_raw.static_files.apps

  static_files_map = {
    for app in local.static_files_apps_raw :
    app.app_name => merge(app, {
      bucket_name = local.static_files_bucket_name
    })
  }

  sns_map = {
    for collection, config in yamldecode(file(var.sns_yaml)).sns :
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
  }
}

############################################################
# 6. IAM role plumbing
############################################################
locals {
  user_role_map = { for u in local.raw_users : u.userName => u.roles }
  user_limits   = { for u in local.raw_users : u.userName => try(u.limit, null) }

  role_types = {
    admin          = "privileged"
    developer      = "privileged"
    serviceAccount = "privileged"
    readOnly       = "readonly"
  }

  # Build the giant role-definition matrix once;
  # module.iam_roles will consume it.
  role_matrix = {
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
  }

  ########################################################################
  #  app_key → list(role names) → ARNs (read/write split)
  ########################################################################
  app_roles_map = {
    for app_key in keys(local.app_map) : app_key => distinct(flatten([
      for user, roles in local.user_role_map :
      local.user_limits[user] == null || contains(local.user_limits[user], app_key)
      ? roles : []
    ]))
  }

  app_role_arns_read = {
    for app_key, roles in local.app_roles_map :
    app_key => [for r in roles : module.iam_roles.role_arns[r]
    if local.role_types[r] == "readonly"]
  }

  app_role_arns_write = {
    for app_key, roles in local.app_roles_map :
    app_key => [for r in roles : module.iam_roles.role_arns[r]
    if local.role_types[r] == "privileged"]
  }
}

############################################################
# 7. Helper locals – first serviceAccount creds found
############################################################
locals {
  sa_access_keys = [
    for u, rs in local.user_role_map :
    module.iam_users[u].access_key_id
    if contains(rs, "serviceAccount")
  ]

  sa_secret_keys = [
    for u, rs in local.user_role_map :
    module.iam_users[u].secret_access_key
    if contains(rs, "serviceAccount")
  ]
}

############################################################
# Create Static Bucket
# This is a shared bucket for all static uploads.
############################################################
resource "aws_s3_bucket" "static_shared" {
  bucket = local.static_files_bucket_name
}

resource "aws_s3_bucket_public_access_block" "static_shared" {
  bucket                  = aws_s3_bucket.static_shared.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "allow_public" {
  bucket = aws_s3_bucket.static_shared.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicRead"
      Effect    = "Allow"
      Principal = "*"
      Action    = ["s3:GetObject"]
      Resource  = "${aws_s3_bucket.static_shared.arn}/*"
    }]
  })
}

############################################################
# Cloudfront Keys and key Groups
############################################################
resource "aws_cloudfront_public_key" "global_keys" {
  for_each = toset(local.active_public_keys)

  name        = "${each.key}-public-key"
  encoded_key = file("${path.module}/../private/cloudfront/rsa_keys/public/${each.key}-public-key.pem")
  comment     = "Global CloudFront Public Key: ${each.key}"

  lifecycle {
    ignore_changes  = [encoded_key]
  }
}

resource "aws_cloudfront_key_group" "global_key_groups" {
  for_each = local.cf_group_map

  name  = each.key
  items = [
    for key in each.value.keys :
    aws_cloudfront_public_key.global_keys[key].id
  ]

  comment = "CloudFront KeyGroup for ${each.key}"
}
