#!/bin/bash
environment="dev"

echo "About to run terraform destroy"
sleep 1

echo "Changing to root directory"
cd "../src"

terraform destroy -var-file="./env/$environment.tfvars"