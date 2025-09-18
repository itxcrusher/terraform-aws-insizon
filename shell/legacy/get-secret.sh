#!/bin/bash
secretId="myfrion-dev-secrets-manager"
versionStage=("AWSCURRENT" "AWSPENDING")


aws secretsmanager get-secret-value \
    --secret-id $secretId \
    --version-stage "${versionStage[0]}"


# echo "$cat"
# aws secretsmanager update-secret-version-stage \
#     --secret-id $secretId \
#     --version-stage "${versionStage[0]}" \
#     --remove-from-version-id "terraform-20250427003349013900000043"