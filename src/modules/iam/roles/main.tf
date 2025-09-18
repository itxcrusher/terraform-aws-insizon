############################################
# modules/iam/roles/main.tf  (global)
# Creates one IAM role per key in role_matrix.
# Physical names are env-scoped.
############################################

# Derive concrete names once (env-scoped)
locals {
  role_names = {
    for r, _ in var.role_matrix :
    r => "${var.name_prefix}${r}${var.env != "" ? "-${var.env}" : ""}${var.name_suffix}"
  }
  inline_policy_names = {
    for r, _ in var.role_matrix :
    r => "${local.role_names[r]}-inline"
  }
}

# Trust policy
data "aws_iam_policy_document" "trust" {
  for_each = var.role_matrix
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = each.value.principal_arns
    }
  }
}

# Permissions
data "aws_iam_policy_document" "policy" {
  for_each = var.role_matrix

  statement {
    sid       = "BaseActions"
    actions   = each.value.base_actions
    effect    = "Allow"
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = length(each.value.extra_actions) > 0 ? [1] : []
    content {
      sid       = "ExtraActions"
      actions   = each.value.extra_actions
      effect    = "Allow"
      resources = ["*"]
    }
  }
}

# Role (env-scoped physical name)
resource "aws_iam_role" "this" {
  for_each           = var.role_matrix
  name               = local.role_names[each.key]
  assume_role_policy = data.aws_iam_policy_document.trust[each.key].json
  description        = "Managed by Terraform for ${each.key} (${var.env})"
  tags               = var.tags
}

# Inline policy (name matches physical role, easier to audit)
resource "aws_iam_role_policy" "inline" {
  for_each = var.role_matrix
  name     = local.inline_policy_names[each.key]
  role     = aws_iam_role.this[each.key].id
  policy   = data.aws_iam_policy_document.policy[each.key].json
}
