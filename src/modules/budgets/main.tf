############################################
# AWS Budgets – flexible alert definition
############################################
resource "aws_sns_topic" "budget_alert" {
  name = "${var.app_key}-budget-alert"
}

resource "aws_budgets_budget" "this" {
  name              = var.app_key
  budget_type       = var.cfg.budget_type
  limit_amount      = var.cfg.limit_amount
  limit_unit        = var.cfg.limit_unit
  time_unit         = var.cfg.time_unit
  time_period_start = var.cfg.start_date

  notification {
    comparison_operator        = var.cfg.comparison_operator
    threshold                  = var.cfg.threshold
    threshold_type             = var.cfg.threshold_type
    notification_type          = var.cfg.notification_type
    subscriber_email_addresses = length(var.cfg.email_recipients) > 0 ? var.cfg.email_recipients : ["alerts@${var.app_key}.com"]
  }

  depends_on = [aws_sns_topic.budget_alert]
}
