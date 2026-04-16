#!/bin/bash

# =============================================================================
# ATOMIA CLOUD SUITE — Backup Script v2.0
# Daily encrypted backup of all persistent volumes with rotation
# =============================================================================

set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────
BACKUP_ROOT="${BACKUP_ROOT:-./backups}"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_DIR="$BACKUP_ROOT/$DATE"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
COMPRESS_LEVEL="${COMPRESS_LEVEL:-6}"   # 1 (fast) – 9 (best)
LOG_FILE="$BACKUP_ROOT/backup.log"

# Optional encryption — set BACKUP_PASSPHRASE in env for AES-256 encryption
ENCRYPT="${BACKUP_PASSPHRASE:+yes}"

# Optional off-site — set RCLONE_REMOTE to e.g. "s3:my-atomia-backups"
RCLONE_REMOTE="${RCLONE_REMOTE:-}"

# Directories to back up (relative to project root)
TARGETS=(
  "data/ollama"
  "data/openwebui"
  "data/code-server"
  "data/gitea"
  "data/gitea-ssh"
  "data/qdrant"
  "data/authelia"
  "data/prometheus"
  "data/grafana"
  "projects"
  "continue"
  "authelia"
  "monitoring"
)

# ── Colours ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

log() { echo -e "${BLUE}[$(date +%T)]${NC} $*" | tee -a "$LOG_FILE"; }
ok()  { echo -e "${GREEN}[$(date +%T)] ✓${NC} $*" | tee -a "$LOG_FILE"; }
warn(){ echo -e "${YELLOW}[$(date +%T)] ⚠${NC} $*" | tee -a "$LOG_FILE"; }
err() { echo -e "${RED}[$(date +%T)] ✗${NC} $*" | tee -a "$LOG_FILE"; }

# ── Check Dependencies ─────────────────────────────────────────────────────────
check_deps() {
    local deps=("tar" "gzip" "date" "du")
    [ -n "$ENCRYPT" ] && deps+=("openssl")
    [ -n "$RCLONE_REMOTE" ] && deps+=("rclone")

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            err "Required dependency '$dep' is not installed."
        fi
    done
}

# ── Start ─────────────────────────────────────────────────────────────────────
check_deps
mkdir -p "$BACKUP_DIR"
log "═══════════════════════════════════════════════"
log " ATOMIA BACKUP — $DATE"
log "═══════════════════════════════════════════════"

TOTAL=0; FAILED=0

for target in "${TARGETS[@]}"; do
  if [ ! -d "$target" ]; then
    warn "Skipping '$target' (directory not found)"
    continue
  fi

  name=$(echo "$target" | tr '/' '_')
  archive="$BACKUP_DIR/${name}.tar.gz"

  log "Backing up '$target'..."

  if tar -czf "$archive" --warning=no-file-changed "$target" 2>/dev/null; then
    size=$(du -sh "$archive" | cut -f1)

    # Optional encryption with openssl
    if [ -n "$ENCRYPT" ]; then
      openssl enc -aes-256-cbc -salt -pbkdf2 \
        -pass env:BACKUP_PASSPHRASE \
        -in "$archive" -out "${archive}.enc" \
        && rm "$archive" && archive="${archive}.enc"
    fi

    ok "'$target' → $(basename "$archive") ($size)"
    TOTAL=$((TOTAL+1))
  else
    err "Failed to archive '$target'"
    FAILED=$((FAILED+1))
  fi
done

# ── Write manifest ─────────────────────────────────────────────────────────────
MANIFEST="$BACKUP_DIR/MANIFEST.txt"
{
  echo "Atomia Cloud Suite Backup"
  echo "Date: $DATE"
  echo "Encrypted: ${ENCRYPT:-no}"
  echo ""
  ls -lh "$BACKUP_DIR"
} > "$MANIFEST"

# ── Rotation — remove old backups ──────────────────────────────────────────────
log "Removing backups older than $RETENTION_DAYS days..."
find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d -mtime +"$RETENTION_DAYS" \
  | while read -r old; do
      warn "Deleting old backup: $(basename "$old")"
      rm -rf "$old"
    done

# ── Off-site sync (optional rclone) ───────────────────────────────────────────
if [ -n "$RCLONE_REMOTE" ]; then
  log "Syncing to off-site: $RCLONE_REMOTE ..."
  if command -v rclone &>/dev/null; then
    rclone sync "$BACKUP_ROOT" "$RCLONE_REMOTE" --progress \
      && ok "Off-site sync complete" \
      || warn "Off-site sync failed (backups still local)"
  else
    warn "rclone not installed — skipping off-site sync"
  fi
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
log "═══════════════════════════════════════════════"
log " SUMMARY: $TOTAL archived, $FAILED failed"
log " Location: $BACKUP_DIR"
log "═══════════════════════════════════════════════"

[ "$FAILED" -eq 0 ] && exit 0 || exit 1
