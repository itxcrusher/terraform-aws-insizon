############################################################
# main.tf – creates one IAM user + keys (+ optional console pwd)
############################################################

# ── User ──────────────────────────────────────────────────
resource "aws_iam_user" "this" {
  name = var.user_name
  tags = merge(var.tags, {
    ManagedBy = "Terraform"
  })
}

# ── Optional console password ─────────────────────────────
resource "aws_iam_user_login_profile" "this" {
  count                   = var.create_console_password ? 1 : 0
  user                    = aws_iam_user.this.name
  password_length         = var.password_length
  password_reset_required = true
}

# ── Access key (PGP-encrypted if key provided) ────────────
resource "aws_iam_access_key" "this" {
  user    = aws_iam_user.this.name
  status  = "Active"
  pgp_key = var.pgp_key != "" ? var.pgp_key : null
}

# ── Attach managed policies ───────────────────────────────
resource "aws_iam_user_policy_attachment" "managed" {
  for_each   = toset(var.policy_arns)
  user       = aws_iam_user.this.name
  policy_arn = each.value
}

# ── Optional CSV export to disk (⚠ keep folder encrypted) ─
resource "local_file" "creds_csv" {
  count    = var.enable_csv_export ? 1 : 0
  content  = local.csv_payload
  filename = local.csv_filename
}
