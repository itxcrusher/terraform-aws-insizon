resource "aws_sns_topic" "this" {
  for_each = var.topics
  name     = each.value.name
}

resource "aws_sns_topic_subscription" "https" {
  for_each = {
    for topic_key, topic in var.topics :
    "${topic_key}" => topic
    if contains(topic.protocols, "https")
  }

  topic_arn = aws_sns_topic.this[each.key].arn
  protocol  = "https"
  endpoint  = each.value.endpoint
}
