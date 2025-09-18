###########################################################################
# outputs.tf – expose handy values
###########################################################################

output "lambda_function_names" {
  value       = { for k, fn in aws_lambda_function.main : k => fn.function_name }
  description = "Map of logical fn key → actual Lambda name"
}

output "lambda_function_urls" {
  value       = { for k, url in aws_lambda_function_url.lambda_url : k => url.function_url }
  description = "Public URLs for HTTP-triggered Lambda functions"
}
