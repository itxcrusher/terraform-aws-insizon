###########################################################################
# cron_triggers.tf – EventBridge rules
###########################################################################

# CloudWatch EventBridge rules (cron)
resource "aws_cloudwatch_event_rule" "cron_trigger" {
  for_each = local.cron_functions

  name                = "${var.app_key}-${each.key}-schedule"
  schedule_expression = [for t in each.value.triggers : t.schedule if lower(t.type) == "cron"][0]
}

# Target Lambda
resource "aws_cloudwatch_event_target" "cron_target" {
  for_each = aws_cloudwatch_event_rule.cron_trigger

  rule = each.value.name
  arn  = aws_lambda_function.main[each.key].arn
}

# Permission so EventBridge can invoke Lambda
resource "aws_lambda_permission" "allow_cron" {
  for_each = aws_cloudwatch_event_rule.cron_trigger

  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main[each.key].function_name
  principal     = "events.amazonaws.com"
  source_arn    = each.value.arn
}
