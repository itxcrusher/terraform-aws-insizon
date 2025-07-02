variable "cfg" {
  description = "Budget config (single YAML row)"
  type = object({
    limit_amount        = number
    limit_unit          = string # USD, EUR, etc.
    budget_type         = string # COST, USAGE, RI_COVERAGE, …
    time_unit           = string # DAILY, MONTHLY, etc.
    start_date          = string # "YYYY-MM-DDThh:mm" (UTC)
    comparison_operator = string # GREATER_THAN | LESS_THAN
    threshold           = number # 80, 90, …
    threshold_type      = string # PERCENTAGE | ABSOLUTE_VALUE
    notification_type   = string # ACTUAL | FORECASTED
    email_recipients    = list(string)
  })
}

variable "app_key" {
  description = "<app>-<env>"
  type        = string
}
