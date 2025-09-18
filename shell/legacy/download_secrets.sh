#!/bin/bash

# A script to download all AWS Secrets Manager secrets into a specific YAML list format.

# Create a directory to store the YAML files, if it doesn't exist.
OUTPUT_DIR="aws_secrets_yaml"
mkdir -p "$OUTPUT_DIR"

echo "Fetching all secret names from AWS Secrets Manager..."

# Get a list of all secret names and remove carriage return characters for Windows compatibility.
SECRET_NAMES=$(aws secretsmanager list-secrets --profile insizon | jq -r '.SecretList[]?.Name' | tr -d '\r')

if [ -z "$SECRET_NAMES" ]; then
  echo "No secrets found or failed to retrieve secrets."
  exit 1
fi

echo "Found secrets. Starting download..."

# Loop through each secret name.
for secret_name in $SECRET_NAMES; do
  echo "Processing secret: $secret_name"

  # Replace forward slashes ('/') in the secret name with underscores ('_')
  # to create a valid filename.
  filename="${secret_name//\//_}.yaml"

  # This jq command now parses the SecretString, converts the key-value pairs
  # into a list of objects (using to_entries), and wraps it all under a top-level 'secrets' key.
  aws secretsmanager get-secret-value --secret-id "$secret_name" --profile insizon | \
  jq '.SecretString | fromjson | {secrets: to_entries}' | \
  python3 -c 'import sys, yaml, json; print(yaml.safe_dump(json.load(sys.stdin)))' > "$OUTPUT_DIR/$filename"

  echo " -> Successfully saved to $OUTPUT_DIR/$filename"
done

echo ""
echo "✅ All secrets have been downloaded to the '$OUTPUT_DIR' directory in the new format."