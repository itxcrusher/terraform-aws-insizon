output "topic_names" {
  value = {
    for k, topic in aws_sns_topic.this :
    k => topic.name
  }
}

output "topic_arns" {
  value = {
    for k, topic in aws_sns_topic.this :
    k => topic.arn
  }
}
