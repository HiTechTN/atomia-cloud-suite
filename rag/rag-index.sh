#!/bin/bash

# =============================================================================
# ATOMIA — Project RAG Indexer
# Chunks and indexes the current project into Qdrant for context-aware AI
# Usage: ./rag-index.sh [project-dir] [collection-name]
#   project-dir:      path to index (default: /projects or $PWD)
#   collection-name:  Qdrant collection name (default: derived from dir name)
# =============================================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log()  { echo -e "${BLUE}[rag] ▶${NC} $*"; }
ok()   { echo -e "${GREEN}[rag] ✓${NC} $*"; }
warn() { echo -e "${YELLOW}[rag] ⚠${NC} $*"; }
err()  { echo -e "${RED}[rag] ✗${NC} $*"; exit 1; }

# ── Config ─────────────────────────────────────────────────────────────────────
QDRANT_URL="${QDRANT_URL:-http://localhost:6333}"
QDRANT_API_KEY="${QDRANT_API_KEY:-}"
OLLAMA_URL="${OLLAMA_HOST:-http://localhost:11434}"
EMBED_MODEL="${RAG_EMBED_MODEL:-nomic-embed-text}"
CHUNK_SIZE="${RAG_CHUNK_SIZE:-512}"     # tokens per chunk
CHUNK_OVERLAP="${RAG_CHUNK_OVERLAP:-64}"

PROJECT_DIR="${1:-/projects}"
[ -d "$PROJECT_DIR" ] || err "Project directory '$PROJECT_DIR' not found"
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

COLLECTION="${2:-$(basename "$PROJECT_DIR" | tr '[:upper:] ' '[:lower:]-')}"

# File extensions to index (code + docs)
INCLUDE_EXTENSIONS=(
    "ts" "tsx" "js" "jsx" "mjs"
    "py" "go" "rs" "java" "kt" "swift"
    "c" "cpp" "h" "hpp"
    "sh" "bash"
    "md" "txt" "rst"
    "json" "yaml" "yml" "toml"
    "sql" "graphql"
    "html" "css" "scss"
    "Dockerfile" "Makefile"
)

# Build find pattern
FIND_PATTERN=""
for ext in "${INCLUDE_EXTENSIONS[@]}"; do
    FIND_PATTERN="$FIND_PATTERN -o -name '*.$ext'"
done
FIND_PATTERN="${FIND_PATTERN:3}"  # strip leading " -o"

log "═══════════════════════════════════════════════"
log " RAG Indexing: $PROJECT_DIR"
log " Collection:   $COLLECTION"
log " Embeddings:   $EMBED_MODEL"
log "═══════════════════════════════════════════════"

# ── Check services ─────────────────────────────────────────────────────────────
curl -sf "$QDRANT_URL/health" >/dev/null || err "Qdrant not reachable at $QDRANT_URL"
curl -sf "$OLLAMA_URL/api/tags" >/dev/null || err "Ollama not reachable at $OLLAMA_URL"

# ── Ensure embedding model is available ───────────────────────────────────────
log "Checking embedding model '$EMBED_MODEL'..."
if ! curl -sf "$OLLAMA_URL/api/tags" | grep -q "$EMBED_MODEL"; then
    log "Pulling embedding model '$EMBED_MODEL'..."
    curl -sf "$OLLAMA_URL/api/pull" \
        -d "{\"name\": \"$EMBED_MODEL\"}" >/dev/null
    ok "Model pulled"
fi

# ── Create or recreate Qdrant collection ──────────────────────────────────────
QDRANT_HEADERS=(-H "Content-Type: application/json")
[ -n "$QDRANT_API_KEY" ] && QDRANT_HEADERS+=(-H "api-key: $QDRANT_API_KEY")

log "Creating Qdrant collection '$COLLECTION'..."
curl -sf -X DELETE "$QDRANT_URL/collections/$COLLECTION" "${QDRANT_HEADERS[@]}" >/dev/null 2>&1 || true
curl -sf -X PUT "$QDRANT_URL/collections/$COLLECTION" \
    "${QDRANT_HEADERS[@]}" \
    -d '{
        "vectors": { "size": 768, "distance": "Cosine" },
        "optimizers_config": { "default_segment_number": 2 },
        "replication_factor": 1
    }' >/dev/null
ok "Collection '$COLLECTION' ready"

# ── Find and index files ───────────────────────────────────────────────────────
FILE_COUNT=0
CHUNK_COUNT=0
POINT_ID=1

# Collect files, skip node_modules / .git / build dirs
mapfile -t FILES < <(
    find "$PROJECT_DIR" \
        \( -path "*/node_modules*" -o -path "*/.git*" \
           -o -path "*/dist/*" -o -path "*/build/*" \
           -o -path "*/__pycache__/*" -o -path "*/.venv/*" \) \
        -prune -o \
        \( $FIND_PATTERN \) -print 2>/dev/null | head -5000
)

log "Found ${#FILES[@]} files to index..."

BATCH=()
BATCH_IDS=()

flush_batch() {
    if [ ${#BATCH[@]} -eq 0 ]; then return; fi

    # Build points JSON
    POINTS_JSON="["
    for i in "${!BATCH[@]}"; do
        bid="${BATCH_IDS[$i]}"
        # embed
        EMBED=$(curl -sf "$OLLAMA_URL/api/embeddings" \
            -H "Content-Type: application/json" \
            -d "{\"model\": \"$EMBED_MODEL\", \"prompt\": $(echo "${BATCH[$i]}" | jq -Rs .)}" \
            | jq '.embedding')

        META=$(echo "${BATCH[$i]}" | head -c 200 | jq -Rs . | head -c 300)
        POINTS_JSON+="{ \"id\": $bid, \"vector\": $EMBED, \"payload\": { \"text\": $(echo "${BATCH[$i]}" | jq -Rs .), \"file\": \"${BATCH_FILES[$i]:-unknown}\" } },"
    done
    POINTS_JSON="${POINTS_JSON%,}]"

    curl -sf -X PUT "$QDRANT_URL/collections/$COLLECTION/points" \
        "${QDRANT_HEADERS[@]}" \
        -d "{\"points\": $POINTS_JSON}" >/dev/null

    BATCH=()
    BATCH_IDS=()
    BATCH_FILES=()
}

declare -a BATCH_FILES=()

for file in "${FILES[@]}"; do
    [ -f "$file" ] || continue
    content=$(cat "$file" 2>/dev/null)
    [ -z "$content" ] && continue

    FILE_COUNT=$((FILE_COUNT + 1))
    rel_path="${file#$PROJECT_DIR/}"

    # Split into chunks (simple line-based chunking)
    line_count=$(wc -l < "$file")
    lines_per_chunk=$((CHUNK_SIZE / 5))   # ~5 tokens per line heuristic
    [ "$lines_per_chunk" -lt 10 ] && lines_per_chunk=10

    start=1
    while [ $start -le $((line_count + 1)) ]; do
        end=$((start + lines_per_chunk - 1))
        chunk=$(sed -n "${start},${end}p" "$file" 2>/dev/null)
        [ -z "$chunk" ] && break

        BATCH+=("$chunk")
        BATCH_IDS+=("$POINT_ID")
        BATCH_FILES+=("$rel_path:L${start}-${end}")
        POINT_ID=$((POINT_ID + 1))
        CHUNK_COUNT=$((CHUNK_COUNT + 1))
        start=$((end - CHUNK_OVERLAP + 1))

        # Flush every 10 chunks to avoid oversized requests
        if [ ${#BATCH[@]} -ge 10 ]; then flush_batch; fi
    done

    [ $((FILE_COUNT % 20)) -eq 0 ] && log "  Indexed $FILE_COUNT files, $CHUNK_COUNT chunks..."
done

flush_batch

log "═══════════════════════════════════════════════"
ok " Indexed $FILE_COUNT files into $CHUNK_COUNT chunks"
ok " Collection: '$COLLECTION' in Qdrant"
log "═══════════════════════════════════════════════"
echo ""
echo -e "${GREEN}Use in Continue chat: @codebase or @${COLLECTION}${NC}"
echo ""
