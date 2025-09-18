#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 && pwd)"
source "$SCRIPT_DIR/common.sh"

ENVIRONMENT="${1:-}"; require_env "$ENVIRONMENT"

read -r -p "Confirm destroy for '$ENVIRONMENT' (type 'destroy'): " CONFIRM
[[ "$CONFIRM" == "destroy" ]] || { echo "Aborted."; exit 1; }

tf_backend_init "$ENVIRONMENT"
tf_format_validate

cd "$TF_ROOT"
terraform destroy -input=false -auto-approve
