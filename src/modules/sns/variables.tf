variable "topics" {
  description = "Map of SNS topics and their subscriptions"
  type = map(object({
    name      = string
    endpoint  = string
    protocols = list(string)
  }))
}
