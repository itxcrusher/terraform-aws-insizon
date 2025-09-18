#!/usr/bin/env bash
# Ensure S3 backend bucket + DynamoDB lock table exist (idempotent)
# Maple: reads profile from backend; exports it locally only (CI uses role).

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && (git rev-parse --show-toplevel 2>/dev/null || pwd -P))"
TF_ROOT="$REPO_ROOT/src"
TF_BACKEND_DIR="$TF_ROOT/backends"

export AWS_PAGER=""
export AWS_CLI_AUTO_PROMPT=off
export AWS_SDK_LOAD_CONFIG=1

require_env() {
  local env="${1:-}"; [[ -n "$env" ]] || { echo "Error: env required (dev|qa|prod)"; exit 1; }
  case "$env" in dev|qa|prod) ;; *) echo "Error: invalid env '$env'"; exit 1 ;; esac
}

parse_backend_kv() {
  local file="$1" key="$2"
  awk -v k="^${key}[[:space:]]*=" '
    $0 ~ k {
      sub(/^[^=]*=[[:space:]]*/, "", $0)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
      gsub(/^"|"$/, "", $0)
      print $0; exit
    }' "$file"
}

ensure_s3_bucket() {
  local bucket="$1" region="$2"
  set +e
  local msg rc; msg="$(aws s3api head-bucket --bucket "$bucket" 2>&1)"; rc=$?
  set -e
  if [[ $rc -eq 0 ]]; then echo "S3 bucket '$bucket' exists."; return 0; fi
  if echo "$msg" | grep -qiE 'PermanentRedirect|AuthorizationHeaderMalformed|301|403'; then
    echo "S3 bucket '$bucket' exists but is not accessible with current creds/region."; return 2
  fi
  if echo "$msg" | grep -qiE '404|NoSuchBucket|Not ?Found'; then
    echo "Creating S3 bucket '$bucket' in $region..."
    if [[ "$region" == "us-east-1" ]]; then
      aws s3api create-bucket --bucket "$bucket" --region "$region"
    else
      aws s3api create-bucket --bucket "$bucket" --region "$region" \
        --create-bucket-configuration LocationConstraint="$region"
    fi
    echo "Blocking public access, enabling versioning + AES256 encryption..."
    aws s3api put-public-access-block --bucket "$bucket" \
      --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
    aws s3api put-bucket-versioning --bucket "$bucket" --versioning-configuration Status=Enabled
    aws s3api put-bucket-encryption --bucket "$bucket" \
      --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
    return 0
  fi
  echo "head-bucket error for '$bucket': $msg"; return 2
}

ensure_dynamodb_table() {
  local table="$1" region="$2"
  if aws dynamodb describe-table --table-name "$table" --region "$region" >/dev/null 2>&1; then
    echo "DynamoDB table '$table' exists."
  else
    echo "Creating DynamoDB table '$table' in region '$region'..."
    aws dynamodb create-table \
      --table-name "$table" \
      --attribute-definitions AttributeName=LockID,AttributeType=S \
      --key-schema AttributeName=LockID,KeyType=HASH \
      --billing-mode PAY_PER_REQUEST \
      --region "$region"
    aws dynamodb wait table-exists --table-name "$table" --region "$region"
  fi
}

main() {
  local env="${1:-}"; require_env "$env"

  local tfb="$TF_BACKEND_DIR/${env}.hcl"
  [[ -f "$tfb" ]] || { echo "Error: backend file not found: $tfb"; exit 1; }

  local bucket region ddb profile
  bucket="$(parse_backend_kv "$tfb" bucket)"
  region="$(parse_backend_kv "$tfb" region)"
  ddb="$(parse_backend_kv "$tfb" dynamodb_table)"
  profile="$(parse_backend_kv "$tfb" profile || true)"

  [[ -n "$bucket" && -n "$region" ]] || { echo "Error: bucket/region must be defined."; exit 1; }

  export AWS_DEFAULT_REGION="$region"

  # Export profile for local runs only; CI uses its role
  if [[ -z "${CODEBUILD_BUILD_ID:-}" ]]; then
    if [[ -n "$profile" ]]; then
      export AWS_PROFILE="$profile"
      echo "CLI profile: $AWS_PROFILE (from ${env}.hcl)"
    fi
  else
    echo "CI detected; skipping AWS_PROFILE export."
  fi

  echo -n "Caller identity: "
  aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "UNAVAILABLE"

  ensure_s3_bucket "$bucket" "$region"
  case $? in
    0)
      [[ -n "$ddb" ]] && ensure_dynamodb_table "$ddb" "$region"
      echo "Backend prerequisites verified for env '$env'."
      ;;
    2)
      echo "Skipping DynamoDB ensure because S3 access is not confirmed for the current credentials."
      echo "Tip: check AWS_PROFILE and region in $tfb"
      exit 1
      ;;
    *)
      exit 1
      ;;
  esac
}
main "$@"
