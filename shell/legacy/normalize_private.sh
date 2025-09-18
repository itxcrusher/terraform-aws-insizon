#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# dry-run (see what would move)
# bash shell/normalize_private.sh

# actually move
# bash shell/normalize_private.sh --apply

usage() {
  cat <<'USAGE'
normalize_private.sh [-a|--apply] [-r|--root <dir>] [<dir>]

Re-home env-tagged artifacts under:
  private/insizonxcontractor-{dev,qa,prod}-bucket/

Flags:
  -a, --apply      Actually move files (default is dry-run)
  -r, --root DIR   Root directory to scan (default: private)
  <dir>            Positional override for root (same as --root)

Examples:
  bash shell/normalize_private.sh
  bash shell/normalize_private.sh --apply
  bash shell/normalize_private.sh private --apply
  bash shell/normalize_private.sh -r ./private
USAGE
}

ROOT="private"
APPLY=false

# --- args parsing (supports flags in any order) ---
while (( "$#" )); do
  case "$1" in
    -a|--apply) APPLY=true; shift ;;
    -r|--root)
      [[ $# -ge 2 ]] || { echo "Missing value for $1" >&2; usage; exit 1; }
      ROOT="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*)
      echo "Unknown flag: $1" >&2
      usage; exit 1 ;;
    *)
      # positional root override
      ROOT="$1"; shift ;;
  esac
done

DEV_BUCKET="${ROOT}/insizonxcontractor-dev-bucket"
QA_BUCKET="${ROOT}/insizonxcontractor-qa-bucket"
PROD_BUCKET="${ROOT}/insizonxcontractor-prod-bucket"

log()   { printf '[normalize] %s\n' "$*" >&2; }
die()   { printf '[normalize][ERROR] %s\n' "$*" >&2; exit 1; }
mkd()   { $APPLY && mkdir -p "$1" || true; }
do_mv() { $APPLY && mv -v "$1" "$2" || echo "mv '$1' -> '$2'"; }

bucket_for_env() {
  case "$1" in
    prod) echo "$PROD_BUCKET" ;;
    qa)   echo "$QA_BUCKET" ;;
    dev|*) echo "$DEV_BUCKET" ;;
  esac
}

detect_env() {
  local p="$1" b; b="$(basename "$p")"
  [[ "$b" =~ -prod(\.|-) ]] && { echo "prod"; return; }
  [[ "$b" =~ -qa(\.|-)   ]] && { echo "qa";   return; }
  [[ "$p" =~ /prod(/|-) ]] && { echo "prod"; return; }
  [[ "$p" =~ /qa(/|-)   ]] && { echo "qa";   return; }
  echo "dev"
}

ensure_env_tree() {
  local base="$1"
  mkd "$base/cloudfront/id"
  mkd "$base/cloudfront/rsa_keys/private"
  mkd "$base/cloudfront/rsa_keys/public"
  mkd "$base/secret_manager_secrets"
  mkd "$base/lambda"
  mkd "$base/iam_access_keys"
  mkd "$base/static-bucket-insizon"
  mkd "$base/contractors_env"
  mkd "$base/temp"
}

[[ -d "$ROOT" ]] || die "Directory '$ROOT' not found"
ensure_env_tree "$DEV_BUCKET"
ensure_env_tree "$QA_BUCKET"
ensure_env_tree "$PROD_BUCKET"

log "Dry-run = $([[ $APPLY == true ]] && echo no || echo yes). Pass --apply to execute."

# 1) Move stray top-level static assets into dev bucket
if [[ -d "${ROOT}/static-bucket-insizon" ]]; then
  log "Re-homing top-level static-bucket-insizon to DEV bucket"
  mkd "${DEV_BUCKET}/static-bucket-insizon"
  shopt -s dotglob nullglob
  for f in "${ROOT}/static-bucket-insizon/"*; do
    [[ -e "$f" ]] || continue
    do_mv "$f" "${DEV_BUCKET}/static-bucket-insizon/"
  done
  shopt -u dotglob nullglob
  $APPLY && rmdir "${ROOT}/static-bucket-insizon" 2>/dev/null || true
fi

# 2) Move prod/qa artifacts currently under DEV bucket
log "Scanning DEV bucket for prod/qa artifacts to move..."
shopt -s globstar nullglob
for src in "${DEV_BUCKET}"/**/*; do
  [[ -f "$src" ]] || continue
  env="$(detect_env "$src")"
  [[ "$env" == "dev" ]] && continue
  rel="${src#${DEV_BUCKET}/}"
  dest_base="$(bucket_for_env "$env")"
  dest_dir="$(dirname "${dest_base}/${rel}")"
  mkd "$dest_dir"
  do_mv "$src" "${dest_base}/${rel}"
done
shopt -u globstar nullglob

# 3) Sweep the rest of private/ for orphaned prod/qa files
log "Re-scanning entire ${ROOT}/ for misfiled prod/qa files outside env buckets..."
shopt -s globstar nullglob
for src in "${ROOT}"/**/*; do
  [[ -f "$src" ]] || continue
  [[ "$src" == ${DEV_BUCKET}/* || "$src" == ${QA_BUCKET}/* || "$src" == ${PROD_BUCKET}/* ]] && continue
  env="$(detect_env "$src")"
  [[ "$env" == "dev" ]] && continue
  rel="${src#${ROOT}/}"
  dest_base="$(bucket_for_env "$env")"
  dest="${dest_base}/${rel}"
  mkd "$(dirname "$dest")"
  do_mv "$src" "$dest"
done
shopt -u globstar nullglob

log "Done."
