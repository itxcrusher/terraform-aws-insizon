############################################
# modules/iam/roles/main.tf  (global)
# Creates:
#  • One IAM role per key in role_matrix
############################################

# Dynamic IAM roles (privileged, readonly, etc.)
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

resource "aws_iam_role" "this" {
  for_each           = var.role_matrix
  name               = each.key
  assume_role_policy = data.aws_iam_policy_document.trust[each.key].json
  description        = "Managed by Terraform for ${each.key} role"
  tags               = var.tags
}

resource "aws_iam_role_policy" "inline" {
  for_each = var.role_matrix
  name     = "${each.key}-inline"
  role     = aws_iam_role.this[each.key].id
  policy   = data.aws_iam_policy_document.policy[each.key].json
}
