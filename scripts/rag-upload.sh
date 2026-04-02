#!/bin/bash

# =============================================================================
# ATOMIA — RAG Document Uploader
# Ingests documents (PDF, TXT, MD) into Qdrant for context-aware AI
# Usage: ./rag-upload.sh <file-path> [collection-name]
# =============================================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log()  { echo -e "${BLUE}[rag-upload] ▶${NC} $*"; }
ok()   { echo -e "${GREEN}[rag-upload] ✓${NC} $*"; }
warn() { echo -e "${YELLOW}[rag-upload] ⚠${NC} $*"; }
err()  { echo -e "${RED}[rag-upload] ✗${NC} $*"; exit 1; }

# ── Config ─────────────────────────────────────────────────────────────────────
QDRANT_URL="${QDRANT_URL:-http://localhost:6333}"
QDRANT_API_KEY="${QDRANT_API_KEY:-}"
OLLAMA_URL="${OLLAMA_HOST:-http://localhost:11434}"
EMBED_MODEL="${RAG_EMBED_MODEL:-nomic-embed-text}"
CHUNK_SIZE="${RAG_CHUNK_SIZE:-512}"
CHUNK_OVERLAP="${RAG_CHUNK_OVERLAP:-64}"

if [ -z "${1:-}" ]; then
    echo "Usage: $0 <file-path> [collection-name]"
    exit 1
fi

FILE_PATH="$1"
[ -f "$FILE_PATH" ] || err "File '$FILE_PATH' not found"

COLLECTION="${2:-documents}"
COLLECTION="$(echo "$COLLECTION" | tr '[:upper:] ' '[:lower:]-')"

# ── Check Services ─────────────────────────────────────────────────────────────
curl -sf "$QDRANT_URL/health" >/dev/null || err "Qdrant not reachable"
curl -sf "$OLLAMA_URL/api/tags" >/dev/null || err "Ollama not reachable"

# ── Prepare Collection ────────────────────────────────────────────────────────
QDRANT_HEADERS=(-H "Content-Type: application/json")
[ -n "$QDRANT_API_KEY" ] && QDRANT_HEADERS+=(-H "api-key: $QDRANT_API_KEY")

log "Ensuring collection '$COLLECTION' exists..."
if ! curl -sf "$QDRANT_URL/collections/$COLLECTION" "${QDRANT_HEADERS[@]}" >/dev/null; then
    log "Creating collection '$COLLECTION'..."
    curl -sf -X PUT "$QDRANT_URL/collections/$COLLECTION" \
        "${QDRANT_HEADERS[@]}" \
        -d '{
            "vectors": { "size": 768, "distance": "Cosine" },
            "optimizers_config": { "default_segment_number": 2 }
        }' >/dev/null
    ok "Collection created"
fi

# ── Extract Text ──────────────────────────────────────────────────────────────
log "Extracting text from $(basename "$FILE_PATH")..."
CONTENT=""
EXT="${FILE_PATH##*.}"

if [[ "$EXT" == "pdf" ]]; then
    # Simple PDF text extraction if pdftotext is available, else fallback
    if command -v pdftotext >/dev/null; then
        CONTENT=$(pdftotext "$FILE_PATH" -)
    else
        warn "pdftotext not found. Use a TXT or MD file instead, or install poppler-utils."
        err "Cannot process PDF without pdftotext"
    fi
else
    CONTENT=$(cat "$FILE_PATH")
fi

[ -z "$CONTENT" ] && err "No content extracted from file"

# ── Chunk and Embed ───────────────────────────────────────────────────────────
log "Chunking and embedding..."
TEMP_FILE=$(mktemp)
echo "$CONTENT" > "$TEMP_FILE"

line_count=$(wc -l < "$TEMP_FILE")
POINT_ID=$(date +%s%N | cut -b1-15) # Generate a semi-random ID

start=1
while [ $start -le $((line_count + 1)) ]; do
    end=$((start + 20)) # Simple 20-line chunks
    chunk=$(sed -n "${start},${end}p" "$TEMP_FILE" | tr -d '\000-\031')
    [ -z "$chunk" ] && break

    # Get Embedding
    EMBED=$(curl -sf "$OLLAMA_URL/api/embeddings" \
        -H "Content-Type: application/json" \
        -d "{\"model\": \"$EMBED_MODEL\", \"prompt\": $(echo "$chunk" | jq -Rs .)}" \
        | jq '.embedding')

    # Push to Qdrant
    curl -sf -X PUT "$QDRANT_URL/collections/$COLLECTION/points" \
        "${QDRANT_HEADERS[@]}" \
        -d "{
            \"points\": [
                {
                    \"id\": $POINT_ID,
                    \"vector\": $EMBED,
                    \"payload\": {
                        \"text\": $(echo "$chunk" | jq -Rs .),
                        \"source\": \"$(basename "$FILE_PATH")\",
                        \"lines\": \"$start-$end\"
                    }
                }
            ]
        }" >/dev/null

    POINT_ID=$((POINT_ID + 1))
    start=$((end - 5)) # Overlap
done

rm "$TEMP_FILE"
ok "Successfully ingested $(basename "$FILE_PATH") into '$COLLECTION'"
echo -e "${GREEN}You can now ask questions about this document in Open WebUI using RAG.${NC}"
