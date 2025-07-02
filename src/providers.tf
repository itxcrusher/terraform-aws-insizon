# Providers 
# providers.ts is the file where you list and configure your providers to be use. Ex Aws, Azure, Gcp
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

}



locals {
  # Preferred region is use-east-2
  # https://awsregion.info/
  US_East1_NorthVirginia   = "us-east-1"
  US_East2_Ohio            = "us-east-2"
  US_West1_NorthCalifornia = "us-west-1"
  US_West2_Oregon          = "us-west-2"
}


# Configure the AWS Provider
# region - Where all your infrastruture code will be deployed
provider "aws" {
  region                   = local.US_East2_Ohio
  profile                  = "default"
  shared_credentials_files = ["~/.aws/credentials"]
}