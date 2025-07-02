#!/bin/bash

set -e

# Usage: ./beanstalk_bucket.sh [--delete]

DELETE_BUCKET=false
if [[ "$1" == "--delete" ]]; then
  DELETE_BUCKET=true
fi

# Find all Elastic Beanstalk buckets in your account
BEANSTALK_BUCKETS=$(aws s3api list-buckets --query "Buckets[?starts_with(Name, 'elasticbeanstalk-')].Name" --output text)

if [[ -z "$BEANSTALK_BUCKETS" ]]; then
  echo "No Elastic Beanstalk buckets found."
  exit 0
fi

for BUCKET in $BEANSTALK_BUCKETS; do
  echo "Processing bucket: $BUCKET"

  # Check if a bucket policy exists
  POLICY_EXISTS=$(aws s3api get-bucket-policy --bucket "$BUCKET" --query Policy --output text 2>/dev/null || true)

  if [[ -n "$POLICY_EXISTS" ]]; then
    echo "  ➤ Deleting bucket policy..."
    aws s3api delete-bucket-policy --bucket "$BUCKET"
  else
    echo "  ➤ No bucket policy found."
  fi

  if $DELETE_BUCKET; then
    echo "  ➤ Emptying bucket..."
    aws s3 rm "s3://$BUCKET" --recursive

    echo "  ➤ Deleting bucket..."
    aws s3api delete-bucket --bucket "$BUCKET"
  fi
done

echo "✅ Done."
