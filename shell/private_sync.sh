#!/usr/bin/env bash
# Minimal sync of ./private <-> s3://insizon-aws-private/private
# Actions: pull | push | dry-pull | dry-push
# Requirements: aws cli must be authenticated (profile/role).

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && (git rev-parse --show-toplevel 2>/dev/null || pwd -P))"
LOCAL_DIR="$REPO_ROOT/private"
S3_URI="s3://insizon-aws-private"

# Preflight: verify AWS creds are loaded (from prompt.sh/require_env)
if ! acct="$(aws sts get-caller-identity --query 'Account' --output text 2>/dev/null)"; then
  echo "[private] ERROR: No AWS credentials. Run via shell/tf/prompt.sh so the backend-selected profile/region are exported." >&2
  exit 1
fi
echo "[private] Using AWS account: $acct  profile=${AWS_PROFILE:-<unset>}  region=${AWS_DEFAULT_REGION:-<unset>}"

usage() {
  cat >&2 <<EOF
Usage: $(basename "$0") [pull|push|dry-pull|dry-push]

  pull       Download from $S3_URI/ -> $LOCAL_DIR/
  push       Upload   from $LOCAL_DIR/ -> $S3_URI/
  dry-pull   Show what would be downloaded (no changes)
  dry-push   Show what would be uploaded (no changes)
EOF
}

cmd="${1:-}"; [[ -z "$cmd" ]] && { usage; exit 1; }
mkdir -p "$LOCAL_DIR"

common_args=(--only-show-errors --no-progress --delete)

case "$cmd" in
  pull)
    echo "[private] PULL  $S3_URI/  ->  $LOCAL_DIR/"
    aws s3 sync "$S3_URI/" "$LOCAL_DIR/" "${common_args[@]}"
    ;;
  push)
    echo "[private] PUSH  $LOCAL_DIR/ ->  $S3_URI/"
    aws s3 sync "$LOCAL_DIR/" "$S3_URI/" "${common_args[@]}"
    ;;
  dry-pull)
    echo "[private] DRY-RUN PULL"
    aws s3 sync "$S3_URI/" "$LOCAL_DIR/" "${common_args[@]}" --dryrun
    ;;
  dry-push)
    echo "[private] DRY-RUN PUSH"
    aws s3 sync "$LOCAL_DIR/" "$S3_URI/" "${common_args[@]}" --dryrun
    ;;
  *)
    usage; exit 1 ;;
esac

echo "[private] Done."
