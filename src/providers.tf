terraform {
  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Primary AWS provider (most services)
provider "aws" {
  region = local.US_East2_Ohio
}

# SNS / global-ish services that require us-east-1
provider "aws" {
  alias  = "sns"
  region = local.US_East1_NorthVirginia
}
