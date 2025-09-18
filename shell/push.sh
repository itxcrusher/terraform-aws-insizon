#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && (git rev-parse --show-toplevel 2>/dev/null || pwd -P))"
cd "$REPO_ROOT"

if git diff --quiet && git diff --cached --quiet; then
  echo "No changes to commit."; exit 0
fi

git add -A
git commit -m "Infra updates"
git push
