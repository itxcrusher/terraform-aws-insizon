# Remote backend configuration for qa environment
bucket         = "insizon-terraform-remote-state-backend-bucket"
key            = "qa.tfstate"
region         = "us-east-2"
dynamodb_table = "terraform-locks"
encrypt        = true
profile        = "insizon"
shared_credentials_file = "~/.aws/credentials"
