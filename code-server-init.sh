#!/bin/bash

# =============================================================================
# Atomia Code Server Init v3.0
# - Applies Continue config
# - Injects Gitea SSH key & git global config
# - Installs custom extensions from EXTENSION_URLS
# - Sets up remote debug helpers
# =============================================================================

set -e

log()  { echo "[init] $*"; }
ok()   { echo "[init] ✓ $*"; }
warn() { echo "[init] ⚠ $*"; }

log "Starting Atomia Code Server initialisation..."

# ── 1. Continue.dev config ────────────────────────────────────────────────────
if [ -f /extension/continue/config.json ]; then
    mkdir -p ~/.continue
    cp /extension/continue/config.json ~/.continue/config.json
    ok "Continue config applied"
fi

# ── 2. Gitea SSH key injection ─────────────────────────────────────────────────
# Creates a dedicated ed25519 key for Gitea if one doesn't already exist,
# then writes an SSH config block so `git clone git.atomia` works out-of-the-box.
mkdir -p ~/.ssh && chmod 700 ~/.ssh

if [ ! -f ~/.ssh/id_gitea ]; then
    ssh-keygen -t ed25519 -f ~/.ssh/id_gitea -N "" -C "coder@atomia" -q
    ok "Gitea SSH key generated"
fi

GITEA_HOST="${GITEA_DOMAIN:-localhost}"
GITEA_SSH_PORT="${GITEA_SSH_PORT:-2222}"

# Write SSH config (idempotent)
grep -q "Host atomia-git" ~/.ssh/config 2>/dev/null || cat >> ~/.ssh/config <<EOF

Host atomia-git
    HostName ${GITEA_HOST}
    Port ${GITEA_SSH_PORT}
    User git
    IdentityFile ~/.ssh/id_gitea
    StrictHostKeyChecking no
EOF
chmod 600 ~/.ssh/config

# Display the public key so it can be pasted into Gitea on first run
log "──────────────────────────────────────────────────────────────────────────"
log "Add this SSH public key to Gitea → User Settings → SSH Keys:"
log ""
cat ~/.ssh/id_gitea.pub
log "──────────────────────────────────────────────────────────────────────────"

# ── 3. Git global config ──────────────────────────────────────────────────────
GIT_NAME="${GIT_USER_NAME:-Atomia Developer}"
GIT_EMAIL="${GIT_USER_EMAIL:-dev@atomia.local}"
GITEA_URL="http://${GITEA_HOST}:${GITEA_HTTP_PORT:-3000}"

git config --global user.name  "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
git config --global core.editor "nano"
git config --global init.defaultBranch "main"
git config --global url."ssh://git@atomia-git/".insteadOf "${GITEA_URL}/"

# GitHub integration helpers
if [ -n "${GITHUB_PAT:-}" ]; then
    git config --global url."https://${GITHUB_PAT}@github.com/".insteadOf "https://github.com/"
    ok "GitHub PAT helper configured"
fi

if [ ! -f ~/.ssh/id_github ] && [ -n "${GITHUB_SSH_KEY:-}" ]; then
    echo "$GITHUB_SSH_KEY" | base64 -d > ~/.ssh/id_github
    chmod 600 ~/.ssh/id_github
    grep -q "Host github.com" ~/.ssh/config 2>/dev/null || cat >> ~/.ssh/config <<EOF

Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_github
    StrictHostKeyChecking no
EOF
    ok "GitHub SSH key injected"
fi

ok "Git global config set"

# ── 4. Install extensions from remote URLs ────────────────────────────────────
if [ -n "${EXTENSION_URLS:-}" ]; then
    log "Installing custom extensions..."
    mkdir -p /tmp/vsix
    IFS=',' read -ra URLS <<< "$EXTENSION_URLS"
    for url in "${URLS[@]}"; do
        url="$(echo "$url" | xargs)"   # trim whitespace
        [ -z "$url" ] && continue
        fname="/tmp/vsix/$(basename "$url" | sed 's/[?#].*//')"
        log "  Downloading $(basename "$fname")..."
        curl -fsSL "$url" -o "$fname" \
            && code-server --install-extension "$fname" \
            && ok "  Installed $(basename "$fname")" \
            || warn "  Failed to install $(basename "$fname")"
    done
    rm -rf /tmp/vsix
fi

# ── 5. Install Continue if missing ────────────────────────────────────────────
if ! code-server --list-extensions 2>/dev/null | grep -qi "continue"; then
    log "Installing Continue extension..."
    code-server --install-extension continue.continue 2>/dev/null \
        && ok "Continue extension installed" \
        || warn "Continue install failed — install manually from the marketplace"
fi

# ── 6. Seed project .vscode/launch.json templates ─────────────────────────────
# Copies debug launch configs into /projects if not already present.
LAUNCH_DIR="/projects/.vscode"
if [ ! -f "$LAUNCH_DIR/launch.json" ] && [ -d /extension/debug-templates ]; then
    mkdir -p "$LAUNCH_DIR"
    cp /extension/debug-templates/launch.json "$LAUNCH_DIR/launch.json"
    ok "Debug launch.json seeded in /projects/.vscode/"
fi

# ── 7. RAG index helper alias ─────────────────────────────────────────────────
grep -q "rag-index" ~/.bashrc 2>/dev/null || cat >> ~/.bashrc <<'EOF'

# Atomia Helper Aliases
alias rag-index='bash /extension/rag/rag-index.sh'
alias upload-model='bash /extension/models/custom-model-upload.sh'
alias github-sync='bash /extension/scripts/github-sync.sh'
alias manage-users='bash /extension/scripts/manage-users.sh'
alias rag-upload='bash /extension/scripts/rag-upload.sh'
EOF

ok "Atomia Code Server ready"

# ── Launch code-server ────────────────────────────────────────────────────────
exec /usr/bin/code-server \
    --bind-addr 0.0.0.0:8080 \
    --auth password \
    /projects