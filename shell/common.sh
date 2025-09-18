#!/usr/bin/env bash
# Shared helpers for AWS Terraform repo (env = dev|qa|prod)
# Maple: profile only, no credentials path; safe for local + CI.

set -euo pipefail

# Speed up provider downloads
export TF_PLUGIN_CACHE_DIR="${TF_PLUGIN_CACHE_DIR:-$HOME/.terraform.d/plugin-cache}"
mkdir -p "$TF_PLUGIN_CACHE_DIR"

# Keep CLI quiet & non-interactive
export AWS_PAGER=""
export AWS_CLI_AUTO_PROMPT=off
export AWS_SDK_LOAD_CONFIG=1

# Paths
SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && (git rev-parse --show-toplevel 2>/dev/null || pwd -P))"
TF_ROOT="$REPO_ROOT/src"
TF_BACKEND_DIR="$TF_ROOT/backends"

# Tiny parser for key = "value" in backend HCL
_parse_backend_kv() {
  local file="$1" key="$2"
  awk -v k="^${key}[[:space:]]*=" '
    $0 ~ k {
      sub(/^[^=]*=[[:space:]]*/, "", $0)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
      gsub(/^"|"$/, "", $0)
      print $0; exit
    }' "$file"
}

# Validate env and export TF vars
require_env() {
  local env="${1:-}"
  if [[ -z "$env" ]]; then echo "Error: environment is required (dev|qa|prod)"; exit 1; fi
  case "$env" in dev|qa|prod) ;; *) echo "Error: invalid environment '$env'"; exit 1 ;; esac

  # single env knob
  export TF_VAR_env="$env"
  # if you still have app_environment variable, wire it too
  if grep -q 'variable[[:space:]]*"app_environment"' "$TF_ROOT/variables.tf" 2>/dev/null; then
    export TF_VAR_app_environment="$env"
  fi

  # Pull region/profile from backend so CLI + TF match intentions
  local bfile="$TF_BACKEND_DIR/${env}.hcl"
  if [[ -f "$bfile" ]]; then
    local region profile
    region="$(_parse_backend_kv "$bfile" region || true)"
    profile="$(_parse_backend_kv "$bfile" profile || true)"

    [[ -n "$region"  ]] && export AWS_DEFAULT_REGION="$region"

    # Export profile for local runs only; CodeBuild uses its role (no named profiles)
    if [[ -z "${CODEBUILD_BUILD_ID:-}" ]]; then
      if [[ -n "$profile" ]]; then
        export AWS_PROFILE="$profile"
        echo "Using AWS_PROFILE from backend (${env}.hcl): $AWS_PROFILE"
      fi
    else
      # In CI, do NOT export AWS_PROFILE; let the role creds flow.
      echo "CI detected; skipping AWS_PROFILE export."
    fi
  else
    echo "WARNING: backend file not found: $bfile" >&2
  fi
}

# Initialize TF backend if needed (reads src/backends/<env>.hcl)
tf_backend_init() {
  local env="$1"

  "$SCRIPT_DIR/ensure_backend.sh" "$env"
  cd "$TF_ROOT"

  local backend_cfg="$TF_BACKEND_DIR/${env}.hcl"
  [[ -f "$backend_cfg" ]] || { echo "Error: backend file not found: $backend_cfg"; exit 1; }

  # Region again (harmless)
  local backend_region; backend_region="$(_parse_backend_kv "$backend_cfg" region || true)"
  [[ -n "$backend_region" ]] && export AWS_DEFAULT_REGION="$backend_region"

  local need_init="false"
  [[ ! -d ".terraform" ]] && need_init="true"
  [[ ! -f ".terraform/modules/modules.json" ]] && need_init="true"

  local hash_cmd="" current_backend_hash="" stored_backend_hash="" backend_hash_file="$TF_ROOT/.terraform/backend.sha256"
  if command -v sha256sum >/dev/null 2>&1; then hash_cmd="sha256sum"; elif command -v shasum >/dev/null 2>&1; then hash_cmd="shasum -a 256"; fi
  if [[ -n "$hash_cmd" ]]; then
    current_backend_hash="$($hash_cmd "$backend_cfg" | awk '{print $1}')"
    [[ -f "$backend_hash_file" ]] && stored_backend_hash="$(awk '{print $1}' "$backend_hash_file")"
    [[ "$current_backend_hash" != "$stored_backend_hash" ]] && need_init="true"
  fi

  local modules_hash_file="$TF_ROOT/.terraform/modules.sha256"
  local current_modules_hash=""
  if [[ -n "$hash_cmd" ]] && command -v find >/dev/null 2>&1; then
    current_modules_hash="$(
      find "$TF_ROOT" -type f -name '*.tf' -print0 \
      | sort -z \
      | xargs -0 $hash_cmd 2>/dev/null \
      | $hash_cmd | awk '{print $1}'
    )"
    local stored_modules_hash=""
    [[ -f "$modules_hash_file" ]] && stored_modules_hash="$(awk '{print $1}' "$modules_hash_file")"
    [[ "$current_modules_hash" != "$stored_modules_hash" ]] && need_init="true"
  fi

  [[ -n "${FORCE_TF_INIT:-}" ]] && need_init="true"

  if [[ "$need_init" == "true" ]]; then
    echo "Running: terraform init -reconfigure"
    terraform init -backend-config="$backend_cfg" -reconfigure
    if [[ -n "$hash_cmd" ]]; then
      mkdir -p "$TF_ROOT/.terraform"
      [[ -n "$current_backend_hash" ]] && echo "$current_backend_hash  $(basename "$backend_cfg")" > "$backend_hash_file"
      [[ -n "$current_modules_hash" ]] && echo "$current_modules_hash  modules" > "$modules_hash_file"
    fi
  else
    echo "Skipping terraform init — backend & modules unchanged."
  fi
}

tf_format_validate() {
  cd "$TF_ROOT"
  terraform fmt -recursive
  terraform validate
}
