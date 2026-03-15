#!/bin/bash

# =============================================================================
# ATOMIA — Custom AI Model Upload Script
# Upload a GGUF/safetensors model file and register it in Ollama
# Usage: ./custom-model-upload.sh <model-file> [model-name] [template]
#   model-file:  path to .gguf or .safetensors file
#   model-name:  name to register in Ollama (default: filename without ext)
#   template:    chat | code | general  (Modelfile template to use, default: general)
# =============================================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log()  { echo -e "${BLUE}[model] ▶${NC} $*"; }
ok()   { echo -e "${GREEN}[model] ✓${NC} $*"; }
warn() { echo -e "${YELLOW}[model] ⚠${NC} $*"; }
err()  { echo -e "${RED}[model] ✗${NC} $*"; exit 1; }

OLLAMA_HOST="${OLLAMA_HOST:-http://localhost:11434}"
MODELS_DIR="${OLLAMA_DATA_PATH:-./data/ollama}"

# ── Args ───────────────────────────────────────────────────────────────────────
MODEL_FILE="${1:-}"
MODEL_NAME="${2:-}"
TEMPLATE="${3:-general}"

if [ -z "$MODEL_FILE" ]; then
    echo ""
    echo "  Usage: $0 <model-file.gguf> [model-name] [template: chat|code|general]"
    echo ""
    echo "  Examples:"
    echo "    $0 ./my-llm.gguf                        # auto-name, general template"
    echo "    $0 ./code-llm.gguf my-coder code        # named, code template"
    echo "    $0 ./chat-model.gguf support-bot chat   # named, chat template"
    echo ""
    exit 1
fi

[ ! -f "$MODEL_FILE" ] && err "File not found: $MODEL_FILE"

# Derive model name from filename if not provided
if [ -z "$MODEL_NAME" ]; then
    MODEL_NAME="$(basename "$MODEL_FILE" | sed 's/\.[^.]*$//' | tr '[:upper:]' '[:lower:]' | tr ' _' '-')"
fi

log "═══════════════════════════════════════════════"
log " Uploading custom model: $MODEL_NAME"
log " Source: $MODEL_FILE"
log " Template: $TEMPLATE"
log "═══════════════════════════════════════════════"

# ── Check Ollama is running ────────────────────────────────────────────────────
curl -sf "$OLLAMA_HOST/api/tags" >/dev/null || \
    err "Ollama is not reachable at $OLLAMA_HOST. Is the container running?"

# ── Copy model file into the bind-mounted models directory ────────────────────
DEST_DIR="$MODELS_DIR/custom"
mkdir -p "$DEST_DIR"
DEST_FILE="$DEST_DIR/$(basename "$MODEL_FILE")"

if [ "$MODEL_FILE" != "$DEST_FILE" ]; then
    log "Copying model file to $DEST_FILE ..."
    cp "$MODEL_FILE" "$DEST_FILE"
    ok "Copied"
fi

# ── Generate Modelfile ─────────────────────────────────────────────────────────
MODELFILE_PATH="/tmp/Modelfile.$MODEL_NAME"

case "$TEMPLATE" in
  code)
    cat > "$MODELFILE_PATH" <<EOF
FROM /models/custom/$(basename "$MODEL_FILE")

# Code-specialised system prompt
SYSTEM """You are an expert software engineer and code assistant.
You write clean, efficient, well-documented code.
You explain your reasoning concisely. Always use the language/framework in context."""

PARAMETER temperature 0.1
PARAMETER top_p 0.9
PARAMETER repeat_penalty 1.1
PARAMETER num_ctx 16384
PARAMETER num_predict 4096
EOF
    ;;
  chat)
    cat > "$MODELFILE_PATH" <<EOF
FROM /models/custom/$(basename "$MODEL_FILE")

SYSTEM """You are a helpful, harmless, and honest AI assistant.
You provide clear, accurate, and thoughtful responses."""

PARAMETER temperature 0.7
PARAMETER top_p 0.95
PARAMETER num_ctx 8192
PARAMETER num_predict 4096
EOF
    ;;
  *)  # general
    cat > "$MODELFILE_PATH" <<EOF
FROM /models/custom/$(basename "$MODEL_FILE")

SYSTEM """You are a knowledgeable AI assistant. Be concise, accurate, and helpful."""

PARAMETER temperature 0.5
PARAMETER top_p 0.9
PARAMETER num_ctx 8192
PARAMETER num_predict 2048
EOF
    ;;
esac

ok "Modelfile written: $MODELFILE_PATH"

# ── Create the model in Ollama ─────────────────────────────────────────────────
log "Registering '$MODEL_NAME' in Ollama..."

# The Modelfile path must be accessible inside the Ollama container.
# We stream the Modelfile content via the API instead.
MODELFILE_CONTENT=$(cat "$MODELFILE_PATH")

curl -sf "$OLLAMA_HOST/api/create" \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"$MODEL_NAME\", \"modelfile\": $(echo "$MODELFILE_CONTENT" | jq -Rs .)}" \
    | while IFS= read -r line; do
        status=$(echo "$line" | jq -r '.status // empty' 2>/dev/null)
        [ -n "$status" ] && log "  $status"
    done

ok "Model '$MODEL_NAME' registered in Ollama"

# ── Verify ─────────────────────────────────────────────────────────────────────
log "Verifying..."
curl -sf "$OLLAMA_HOST/api/tags" | jq -r '.models[].name' | grep -q "$MODEL_NAME" \
    && ok "Model '$MODEL_NAME' is available via Ollama API" \
    || warn "Model may not be listed yet — check with: docker exec atomia-ollama ollama list"

# ── Cleanup ────────────────────────────────────────────────────────────────────
rm -f "$MODELFILE_PATH"

echo ""
echo -e "${GREEN}Done! Add to continue/config.json:${NC}"
cat <<EOF
{
  "title": "$MODEL_NAME — Custom",
  "provider": "ollama",
  "model": "$MODEL_NAME",
  "apiBase": "http://ollama:11434",
  "contextLength": 8192
}
EOF
echo ""
