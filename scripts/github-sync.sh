#!/bin/bash

# =============================================================================
# ATOMIA — GitHub Integration Helper
# Clone or Sync GitHub repositories into Atomia (Gitea)
# Usage: ./github-sync.sh <github_repo_url> [gitea_repo_name]
# =============================================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log()  { echo -e "${BLUE}[github] ▶${NC} $*"; }
ok()   { echo -e "${GREEN}[github] ✓${NC} $*"; }
warn() { echo -e "${YELLOW}[github] ⚠${NC} $*"; }
err()  { echo -e "${RED}[github] ✗${NC} $*"; exit 1; }

# ── Config ─────────────────────────────────────────────────────────────────────
GITEA_URL="${GITEA_ROOT_URL:-http://gitea:3000}"
GITHUB_PAT="${GITHUB_PAT:-}"

# ── Main ───────────────────────────────────────────────────────────────────────
if [ -z "${1:-}" ]; then
    echo "Usage: $0 <github_repo_url> [target_repo_name]"
    exit 1
fi

GITHUB_REPO="$1"
TARGET_NAME="${2:-$(basename "$GITHUB_REPO" .git)}"

log "Syncing GitHub repository: $GITHUB_REPO"

# 1. Check if authenticated
if [ -z "$GITHUB_PAT" ]; then
    warn "GITHUB_PAT not set. Public repositories only."
fi

# 2. Clone from GitHub
TMP_DIR="/tmp/sync-$(date +%s)"
log "Cloning from GitHub..."
git clone --mirror "$GITHUB_REPO" "$TMP_DIR"

# 3. Push to Gitea
# Note: This assumes the user is already authenticated with Gitea via SSH (id_gitea)
# or we can use the Gitea API if a token is provided.
# For simplicity, we'll use the SSH alias 'atomia-git' created in code-server-init.sh

log "Pushing to Gitea..."
# Check if target repo exists, if not create it (requires Gitea API or just push)
# Here we'll try to push to the user's namespace
git -C "$TMP_DIR" remote add atomia ssh://git@atomia-git/dev/"$TARGET_NAME"
git -C "$TMP_DIR" push --mirror atomia || {
    warn "Push failed. Ensure the repository exists in Gitea or you have permissions."
    err "Manual intervention required: Create repo '$TARGET_NAME' in Gitea first."
}

# ── Cleanup ────────────────────────────────────────────────────────────────────
rm -rf "$TMP_DIR"
ok "Successfully synced $GITHUB_REPO to Atomia Gitea as '$TARGET_NAME'"
