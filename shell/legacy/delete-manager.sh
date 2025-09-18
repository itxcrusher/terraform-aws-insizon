#!/bin/bash
# https://medium.com/geekculture/aws-secrets-manager-and-terraform-state-delete-issue-d740f66cbcb9
secretId="maxgeneye-dev-secrets-manager"

echo "About to run terraform plan"
sleep 1

echo "Changing to root directory"
cd "../src"


echo "About to source project"
source ".env"
sleep 1

echo "About to force delete aws secret"
aws secretsmanager delete-secret \
   --secret-id $secretId \
   --force-delete-without-recovery \
   --region "us-east-2"
sleep 1