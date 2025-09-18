# Remote backend configuration for prod environment
bucket         = "insizon-terraform-remote-state-backend-bucket"
key            = "prod.tfstate"
region         = "us-east-2"
dynamodb_table = "terraform-locks"
encrypt        = true
profile        = "insizon"
shared_credentials_file = "~/.aws/credentials"
