#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 && pwd)"
source "$SCRIPT_DIR/common.sh"

ENVIRONMENT="${1:-}"; OUTPUT_NAME="${2:-}"
require_env "$ENVIRONMENT"
tf_backend_init "$ENVIRONMENT"

cd "$TF_ROOT"
if [[ -z "$OUTPUT_NAME" ]]; then
  terraform output
else
  terraform output -raw "$OUTPUT_NAME"
fi
