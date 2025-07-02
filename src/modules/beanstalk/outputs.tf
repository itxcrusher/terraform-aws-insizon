output "environment_url" {
  description = "CNAME/URL of the EB environment"
  value       = aws_elastic_beanstalk_environment.this.endpoint_url
}
