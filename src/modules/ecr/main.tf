############################################
# modules/ecr/main.tf
# Creates an ECR repository only when
# cfg.create_service = true
############################################

resource "aws_ecr_repository" "main" {
  count = var.cfg.create_service ? 1 : 0

  name                 = local.repo_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = var.cfg.scan_on_push
  }
}

resource "aws_ecr_lifecycle_policy" "main" {
  count = var.cfg.create_service && var.cfg.lifecycle_policy != null ? 1 : 0

  repository = aws_ecr_repository.main[0].name

  policy = (
    var.cfg.lifecycle_policy == "retain-last-20" ? local.default_lifecycle_policy : var.cfg.lifecycle_policy
  )
}
