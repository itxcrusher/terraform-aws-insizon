############################################
# Elastic Beanstalk – single environment
# • Names follow "<service_name>-<env>"
# • All platform-specific fine-tuning lives in YAML
############################################

resource "aws_elastic_beanstalk_application" "this" {
  name = local.service_name
  tags = {
    ManagedBy = "Terraform"
    App       = var.cfg.app_name
    Env       = var.cfg.env
  }
}

# ──────────────────────────────────────────
resource "aws_elastic_beanstalk_environment" "this" {
  name                = "${local.service_name}-${var.cfg.env}"
  application         = aws_elastic_beanstalk_application.this.name
  solution_stack_name = var.cfg.platform
  tier                = var.cfg.tier

  # EC2 profile for Beanstalk instances
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value = aws_iam_instance_profile.beanstalk_profile.name
  }

  # Base ENV marker
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "ENV"
    value     = var.cfg.env
  }

  # Dynamically inject user-defined env vars
  dynamic "setting" {
    for_each = local.env_vars_kv
    content {
      namespace = "aws:elasticbeanstalk:application:environment"
      name      = setting.value.name
      value     = setting.value.value
    }
  }
}
