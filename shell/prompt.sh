#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 && pwd)"

# shellcheck source=./common.sh
source "$SCRIPT_DIR/common.sh"

global_menu() {
  local env="$1"
  while true; do
    {
      echo
      echo "Private bucket sync (env: $env)"
      echo "AWS_PROFILE=${AWS_PROFILE:-<unset>}  AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-<unset>}"
      echo "──────────────────────────────────────────────────────────"
      echo "1) DRY-RUN pull (S3 -> ./private)"
      echo "2) Pull         (S3 -> ./private)"
      echo "3) DRY-RUN push (./private -> S3)"
      echo "4) Push         (./private -> S3)"
      echo "5) Continue to Terraform menu"
      echo "6) Quit"
    } >&2
    read -r -p "Choose: " g
    case "$g" in
      1) bash "$SCRIPT_DIR/private_sync.sh" dry-pull ;;
      2) bash "$SCRIPT_DIR/private_sync.sh" pull     ;;
      3) bash "$SCRIPT_DIR/private_sync.sh" dry-push ;;
      4) bash "$SCRIPT_DIR/private_sync.sh" push     ;;
      5) return 0 ;;   # proceed to TF menu
      6) exit 0 ;;
      *) echo "Invalid option." >&2 ;;
    esac
  done
}

print_env_menu() {
  {
    echo
    echo "Select environment:"
    echo "1) dev"
    echo "2) qa"
    echo "3) prod"
    echo "4) Quit"
  } >&2
}

select_environment() {
  local choice
  while true; do
    print_env_menu
    read -r -p "Enter choice: " choice
    case "$choice" in
      1) printf "dev";  return 0 ;;
      2) printf "qa";   return 0 ;;
      3) printf "prod"; return 0 ;;
      4) exit 0 ;;
      *) echo "Invalid selection." >&2 ;;
    esac
  done
}

terraform_menu() {
  local env="$1"
  while true; do
    {
      echo
      echo "Terraform (env: $env)"
      echo "1) fmt"
      echo "2) plan"
      echo "3) apply"
      echo "4) output"
      echo "5) destroy"
      echo "6) change env (reload backend profile/region)"
      echo "7) quit"
    } >&2
    read -r -p "Choose: " choice
    case "$choice" in
      1) bash "$SCRIPT_DIR/fmt.sh" ;;
      2) bash "$SCRIPT_DIR/plan.sh"   "$env" ;;
      3) bash "$SCRIPT_DIR/apply.sh"  "$env" ;;
      4)
         read -r -p "Output name (empty for all): " on
         [[ -z "$on" ]] && bash "$SCRIPT_DIR/output.sh" "$env" || bash "$SCRIPT_DIR/output.sh" "$env" "$on"
         ;;
      5) bash "$SCRIPT_DIR/destroy.sh" "$env" ;;
      6) return 10 ;;  # signal: change env
      7) exit 0 ;;
      *) echo "Invalid option." >&2 ;;
    esac
  done
}

main() {
  # 1) pick env FIRST
  local env; env="$(select_environment)"

  # 2) load backend-sourced profile/region BEFORE any AWS actions
  require_env "$env"

  # 3) always offer private sync first (now using correct creds/region)
  global_menu "$env"

  # 4) terraform loop; handle non-zero return safely under set -e
  while true; do
    if terraform_menu "$env"; then
      rc=0
    else
      rc=$?   # capture the non-zero (e.g., 10 for “change env”)
    fi

    if [[ $rc -eq 10 ]]; then
      env="$(select_environment)"  # jump back to env picker
      require_env "$env"           # reload backend-sourced profile/region
      global_menu "$env"           # (optional) re-run private sync for new env
    fi
  done
}
main
