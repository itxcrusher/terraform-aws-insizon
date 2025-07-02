#!/bin/bash
environment="$1"

echo "About to run terraform plan"
sleep 1

echo "Changing to root directory"
cd "../src"


echo "About to delete .terraform folder"
rm -rf "./terraform"
sleep 1


echo "About to formate code"
terraform fmt -recursive
sleep 1

echo "About to source project"
source ".env"
sleep 1

echo "About to create .terraform folder"
terraform init
sleep 1

terraform plan -var-file="./env/$environment.tfvars"