#!/bin/bash

# =============================================================================
# ATOMIA CLOUD SUITE — Universal Deploy Script
# Triggered by Gitea webhook via Woodpecker CI or direct call
# Usage: ./deploy.sh <env> <repo_url> <branch> <project_dir>
#   env:         staging | production
#   repo_url:    http://gitea:3000/user/repo.git
#   branch:      main | develop | staging
#   project_dir: /projects/myapp
# =============================================================================

set -euo pipefail

# ── Args / defaults ────────────────────────────────────────────────────────────
ENV="${1:-staging}"
REPO_URL="${2:-}"
BRANCH="${3:-main}"
PROJECT_DIR="${4:-/projects/app}"

# ── Load .env overrides ────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$SCRIPT_DIR/../.env" ] && source "$SCRIPT_DIR/../.env"

# ── Colours ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log()  { echo -e "${BLUE}[$(date +%T)] DEPLOY ▶${NC} $*"; }
ok()   { echo -e "${GREEN}[$(date +%T)] ✓${NC} $*"; }
warn() { echo -e "${YELLOW}[$(date +%T)] ⚠${NC} $*"; }
err()  { echo -e "${RED}[$(date +%T)] ✗${NC} $*"; exit 1; }

# ── Validate ───────────────────────────────────────────────────────────────────
[[ "$ENV" != "staging" && "$ENV" != "production" ]] && \
  err "Unknown environment '$ENV'. Use staging or production."

log "═══════════════════════════════════════════════════"
log " ATOMIA DEPLOY — env=$ENV  branch=$BRANCH"
log "═══════════════════════════════════════════════════"

# ── Compose files per environment ─────────────────────────────────────────────
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.$ENV.yml"
COMPOSE_BASE="$SCRIPT_DIR/../docker-compose.yml"
ENV_FILE="$SCRIPT_DIR/../.env"
ENV_OVERRIDE="$SCRIPT_DIR/.$ENV.env"

# ── Step 1: Pull latest code ───────────────────────────────────────────────────
log "Step 1/5 — Syncing code from $REPO_URL ($BRANCH)..."

if [ -d "$PROJECT_DIR/.git" ]; then
    git -C "$PROJECT_DIR" fetch --all
    git -C "$PROJECT_DIR" reset --hard "origin/$BRANCH"
    ok "Code synced to latest $BRANCH"
elif [ -n "$REPO_URL" ]; then
    git clone --branch "$BRANCH" --depth 1 "$REPO_URL" "$PROJECT_DIR"
    ok "Repository cloned"
else
    warn "No REPO_URL provided — skipping git pull, using existing code"
fi

# ── Step 2: Build Docker image ─────────────────────────────────────────────────
log "Step 2/5 — Building Docker image..."

if [ -f "$PROJECT_DIR/Dockerfile" ]; then
    IMAGE_TAG="atomia-app-$ENV:$(git -C "$PROJECT_DIR" rev-parse --short HEAD 2>/dev/null || echo latest)"
    docker build -t "$IMAGE_TAG" "$PROJECT_DIR"
    ok "Image built: $IMAGE_TAG"
    export APP_IMAGE="$IMAGE_TAG"
else
    warn "No Dockerfile found — skipping build step"
fi

# ── Step 3: Run tests (staging only) ──────────────────────────────────────────
if [[ "$ENV" == "staging" ]]; then
    log "Step 3/5 — Running tests..."
    if [ -f "$PROJECT_DIR/package.json" ]; then
        docker run --rm -v "$PROJECT_DIR:/app" -w /app node:20-alpine \
            sh -c "npm ci --silent && npm test --if-present" \
            && ok "Tests passed" || err "Tests failed — aborting deploy"
    elif [ -f "$PROJECT_DIR/requirements.txt" ]; then
        docker run --rm -v "$PROJECT_DIR:/app" -w /app python:3.11-slim \
            sh -c "pip install -q -r requirements.txt && pytest --tb=short" \
            && ok "Tests passed" || err "Tests failed — aborting deploy"
    else
        warn "No package.json or requirements.txt — skipping tests"
    fi
else
    log "Step 3/5 — Skipping tests (production deploy from pre-validated branch)"
fi

# ── Step 4: Deploy via Docker Compose ─────────────────────────────────────────
log "Step 4/5 — Deploying to $ENV..."

COMPOSE_ARGS="-f $COMPOSE_BASE"
[ -f "$COMPOSE_FILE" ] && COMPOSE_ARGS="$COMPOSE_ARGS -f $COMPOSE_FILE"
ENV_ARGS="--env-file $ENV_FILE"
[ -f "$ENV_OVERRIDE" ] && ENV_ARGS="$ENV_ARGS --env-file $ENV_OVERRIDE"

eval "docker compose $COMPOSE_ARGS $ENV_ARGS up -d --build --remove-orphans"
ok "Services deployed to $ENV"

# ── Step 5: Health check ───────────────────────────────────────────────────────
log "Step 5/5 — Health checking..."

HEALTH_URL="${HEALTH_CHECK_URL:-http://localhost:8080}"
MAX_RETRIES=12; RETRY=0

until curl -sf "$HEALTH_URL" >/dev/null 2>&1 || [ $RETRY -ge $MAX_RETRIES ]; do
    RETRY=$((RETRY+1))
    warn "Waiting for service... ($RETRY/$MAX_RETRIES)"
    sleep 5
done

if [ $RETRY -ge $MAX_RETRIES ]; then
    err "Health check failed after ${MAX_RETRIES} attempts — deployment may be broken"
else
    ok "Service is healthy at $HEALTH_URL"
fi

# ── Done ───────────────────────────────────────────────────────────────────────
log "═══════════════════════════════════════════════════"
ok " DEPLOY COMPLETE — $ENV is live"
log "═══════════════════════════════════════════════════"
