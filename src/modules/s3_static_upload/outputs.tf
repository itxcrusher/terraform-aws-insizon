output "app_name" { value = var.cfg.app_name }
output "uploaded_keys" { value = [for f in aws_s3_object.static_files : f.key] }
