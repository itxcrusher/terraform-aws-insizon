############################################################
# locals.tf – helper payloads & paths
############################################################
# 1.  csv_payload   → one-line CSV containing AK, SK, console pwd
#                    • SK is PGP-encrypted when pgp_key provided
# 2.  csv_filename  → file path under /private/iam_access_keys/
############################################################

locals {
  safe_secret = var.pgp_key != "" ? aws_iam_access_key.this.encrypted_secret : aws_iam_access_key.this.secret

  csv_payload = templatefile("${path.module}/templates/credentials.tftpl", {
    access_key = aws_iam_access_key.this.id
    secret_key = local.safe_secret
    password = (
      length(aws_iam_user_login_profile.this) == 0 ? "N/A" : aws_iam_user_login_profile.this[0].password
    )
  })

  csv_filename = "${path.module}/../../../../private/iam_access_keys/${var.user_name}-keys.csv"
}
