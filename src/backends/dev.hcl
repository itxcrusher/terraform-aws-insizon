# Remote backend configuration for dev environment
bucket         = "insizon-terraform-remote-state-backend-bucket"
key            = "dev.tfstate"
region         = "us-east-2"
dynamodb_table = "terraform-locks"
encrypt        = true
profile        = "insizon"
shared_credentials_file = "~/.aws/credentials"
