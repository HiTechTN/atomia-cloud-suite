#!/bin/bash

# =============================================================================
# ATOMIA — User & Workspace Manager
# Provision isolated development environments with Authelia integration
# Usage: ./manage-users.sh add <username> [password] [github_pat]
#        ./manage-users.sh remove <username>
#        ./manage-users.sh list
# =============================================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log()  { echo -e "${BLUE}[manage] ▶${NC} $*"; }
ok()   { echo -e "${GREEN}[manage] ✓${NC} $*"; }
warn() { echo -e "${YELLOW}[manage] ⚠${NC} $*"; }
err()  { echo -e "${RED}[manage] ✗${NC} $*"; exit 1; }

# ── Config ─────────────────────────────────────────────────────────────────────
AUTH_DB="./authelia/users_database.yml"
USERS_COMPOSE="./docker-compose.users.yml"
WORKSPACES_DIR="./data/workspaces"
BASE_PORT=8444 # Starting port for user code-servers

# ── Helpers ────────────────────────────────────────────────────────────────────
generate_password_hash() {
    local password=$1
    docker run --rm authelia/authelia:latest authelia crypto hash generate argon2 --password "$password" | awk '{print $NF}'
}

get_next_port() {
    if [ ! -f "$USERS_COMPOSE" ]; then
        echo "$BASE_PORT"
        return
    fi
    local last_port=$(grep -oP '(?<=")\d+(?=:8080")' "$USERS_COMPOSE" | sort -n | tail -1)
    if [ -z "$last_port" ]; then
        echo "$BASE_PORT"
    else
        echo $((last_port + 1))
    fi
}

# ── Main Actions ───────────────────────────────────────────────────────────────
action_add() {
    local user=$1
    local pass=${2:-$(openssl rand -base64 12)}
    local github_pat=${3:-}

    log "Provisioning workspace for user: $user"

    # 1. Add to Authelia
    if grep -q "^  $user:" "$AUTH_DB"; then
        warn "User '$user' already exists in Authelia database."
    else
        log "Generating password hash..."
        local hash=$(generate_password_hash "$pass")
        
        cat >> "$AUTH_DB" <<EOF
  $user:
    displayname: "$user"
    password: "$hash"
    email: "$user@atomia.local"
    groups:
      - developers
EOF
        ok "User added to Authelia (Password: $pass)"
    fi

    # 2. Create workspace directories
    local user_dir="$WORKSPACES_DIR/$user"
    mkdir -p "$user_dir/config" "$user_dir/projects" "$user_dir/ssh"
    ok "Workspace directories created at $user_dir"

    # 3. Add to docker-compose.users.yml
    local port=$(get_next_port)
    if [ ! -f "$USERS_COMPOSE" ]; then
        cat > "$USERS_COMPOSE" <<EOF
version: '3.8'
services:
EOF
    fi

    if grep -q "code-server-$user:" "$USERS_COMPOSE"; then
        warn "Docker service for '$user' already exists."
    else
        cat >> "$USERS_COMPOSE" <<EOF
  code-server-$user:
    image: codercom/code-server:latest
    container_name: atomia-codeserver-$user
    restart: unless-stopped
    ports:
      - "$port:8080"
    environment:
      - PASSWORD=$pass
      - GITHUB_PAT=$github_pat
      - GITEA_DOMAIN=\${GITEA_DOMAIN:-localhost}
    volumes:
      - $user_dir/config:/home/coder:rw
      - $user_dir/projects:/projects:rw
      - $user_dir/ssh:/home/coder/.ssh:rw
      - ./continue:/extension/continue:ro
      - ./code-server-init.sh:/usr/local/bin/init.sh:ro
    entrypoint: ["/bin/bash", "/usr/local/bin/init.sh"]
    networks:
      - atomia-network
EOF
        ok "Added service 'code-server-$user' on port $port"
    fi

    log "Updating services..."
    docker compose -f docker-compose.yml -f docker-compose.users.yml up -d
    ok "Workspace is live! Access at: http://localhost:$port (or via proxy /u/$user)"
}

action_remove() {
    local user=$1
    log "Removing user: $user"
    
    # Simple sed based removal (naive but works for this structure)
    # In a real app we'd use a proper YAML parser
    sed -i "/^  $user:/,+5d" "$AUTH_DB"
    
    # Remove from compose (requires careful multi-line sed or just rewrite)
    # Here we'll just warn the user to do it manually for safety
    warn "Please manually remove 'code-server-$user' from $USERS_COMPOSE and restart."
    
    ok "User $user removed from Authelia."
}

action_list() {
    log "Current Users:"
    grep -P '^  \w+(?=:)' "$AUTH_DB" | sed 's/  //;s/://'
}

# ── Routing ────────────────────────────────────────────────────────────────────
COMMAND=${1:-list}
shift || true

case "$COMMAND" in
    add)    action_add "$@" ;;
    remove) action_remove "$@" ;;
    list)   action_list ;;
    *)      err "Unknown command: $COMMAND" ;;
esac
