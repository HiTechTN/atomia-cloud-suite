#!/bin/bash

# =============================================================================
# ATOMIA CLOUD SUITE — Setup Script v4.0
# Installs Docker, creates directories, pulls images, downloads AI models
# =============================================================================

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

banner() { echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"; }

banner
echo -e "${BLUE}  ATOMIA CLOUD SUITE v4.0 — Setup Script${NC}"
echo -e "${BLUE}  Auth · RAG · GPU · Monitoring · Backups${NC}"
banner
echo ""

# =============================================================================
# 1. Docker
# =============================================================================
echo -e "${YELLOW}[1/6] Checking Docker...${NC}"
if command -v docker &>/dev/null; then
    echo -e "${GREEN}✓ Docker $(docker --version)${NC}"
else
    echo -e "${YELLOW}Installing Docker...${NC}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh && rm get-docker.sh
    sudo usermod -aG docker "$USER"
    echo -e "${GREEN}✓ Docker installed${NC}"
fi

# =============================================================================
# 2. Docker Compose
# =============================================================================
echo -e "${YELLOW}[2/6] Checking Docker Compose...${NC}"
if docker compose version &>/dev/null; then
    echo -e "${GREEN}✓ Docker Compose available${NC}"
else
    echo -e "${RED}Docker Compose not found. Install Docker Desktop or the Compose plugin.${NC}"
    exit 1
fi

# =============================================================================
# 3. GPU Detection
# =============================================================================
echo -e "${YELLOW}[3/6] Checking GPU support...${NC}"
if command -v nvidia-smi &>/dev/null; then
    echo -e "${GREEN}✓ NVIDIA GPU detected:${NC}"
    nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader
    echo -e "${GREEN}  Ollama will use GPU acceleration.${NC}"
else
    echo -e "${YELLOW}⚠  No NVIDIA GPU detected — Ollama will run on CPU.${NC}"
    echo -e "${YELLOW}  To enable GPU later: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html${NC}"
fi

# =============================================================================
# 4. Create Data Directories
# =============================================================================
echo -e "${YELLOW}[4/6] Creating data directories...${NC}"

dirs=(
  data/ollama
  data/openwebui
  data/code-server
  data/code-server-ssh
  data/gitea
  data/gitea-ssh
  data/gitea-runner
  data/qdrant
  data/authelia
  data/prometheus
  data/grafana
  projects
  continue
  authelia
  monitoring
  backups
)

for d in "${dirs[@]}"; do
    mkdir -p "$d"
done

# Authelia needs specific permissions
chmod 700 authelia/users_database.yml 2>/dev/null || true

echo -e "${GREEN}✓ All directories created${NC}"

# =============================================================================
# 5. Pull Docker Images
# =============================================================================
echo -e "${YELLOW}[5/6] Pulling Docker images...${NC}"

images=(
  "ollama/ollama:latest"
  "ghcr.io/open-webui/open-webui:main"
  "authelia/authelia:latest"
  "codercom/code-server:latest"
  "gitea/gitea:latest"
  "gitea/act_runner:latest"
  "qdrant/qdrant:latest"
  "jc21/nginx-proxy-manager:latest"
  "prom/prometheus:latest"
  "grafana/grafana:latest"
  "gcr.io/cadvisor/cadvisor:latest"
)

for img in "${images[@]}"; do
    echo "  Pulling $img..."
    docker pull "$img"
done

echo -e "${GREEN}✓ All images pulled${NC}"

# =============================================================================
# 6. Download Initial AI Models
# =============================================================================
echo ""
banner
echo -e "${BLUE}  AI Models Setup${NC}"
banner
echo ""

read -rp "Download initial AI models now? (recommended, requires ~15GB) [Y/n]: " reply
echo ""

if [[ "$reply" =~ ^[Yy]$ ]] || [[ -z "$reply" ]]; then
    echo -e "${YELLOW}Starting temporary Ollama container...${NC}"

    docker run -d --name atomia-ollama-setup \
        -v "$(pwd)/data/ollama:/models" \
        -e OLLAMA_MODELS=/models \
        -p 11434:11434 \
        ollama/ollama:latest

    echo "Waiting for Ollama to be ready..."
    until curl -sf http://localhost:11434/api/tags >/dev/null 2>&1; do sleep 2; done

    models=(
      "deepseek-coder:1.3b"   # Tab autocomplete (small, fast)
      "deepseek-coder"        # Main coding model
      "codellama"             # Coding fallback
      "nomic-embed-text"      # Embeddings for RAG
    )

    for m in "${models[@]}"; do
        echo -e "${GREEN}Downloading $m...${NC}"
        docker exec atomia-ollama-setup ollama pull "$m"
    done

    docker stop atomia-ollama-setup && docker rm atomia-ollama-setup
    echo -e "${GREEN}✓ Models downloaded${NC}"
else
    echo -e "${YELLOW}Skipping. Download later with:${NC}"
    echo "  docker exec atomia-ollama ollama pull deepseek-coder"
fi

# =============================================================================
# Copy .env if not present
# =============================================================================
if [ ! -f .env ] && [ -f .env.example ]; then
    cp .env.example .env
    echo -e "${YELLOW}⚠  .env created from .env.example — edit it before starting!${NC}"
fi

# =============================================================================
# Start All Services
# =============================================================================
echo ""
banner
echo -e "${BLUE}  Starting Atomia Cloud Suite...${NC}"
banner
docker compose up -d
echo "Waiting for services..."
sleep 20

echo ""
banner
echo -e "${GREEN}  ✓ ATOMIA CLOUD SUITE IS RUNNING!${NC}"
banner
echo ""
echo -e "${BLUE}📍 Service URLs:${NC}"
echo -e "  • Open WebUI (Chat)     → http://localhost:8080"
echo -e "  • Code Server (IDE)     → http://localhost:8443"
echo -e "  • Gitea (Git server)    → http://localhost:3000"
echo -e "  • Authelia (SSO)        → http://localhost:9091"
echo -e "  • Grafana (Monitoring)  → http://localhost:3001"
echo -e "  • Prometheus            → http://localhost:9090"
echo -e "  • Ollama API            → http://localhost:11434"
echo -e "  • Nginx Proxy Manager   → http://localhost:81"
echo ""
echo -e "${YELLOW}⚠  Default credentials — CHANGE THESE IN .env:${NC}"
echo -e "  • Authelia admin:   admin / atomia-admin"
echo -e "  • Code Server:      \$CODER_PASSWORD"
echo -e "  • Grafana:          admin / \$GRAFANA_PASSWORD"
echo -e "  • Nginx Proxy Mgr:  admin@example.com / changeme"
echo ""
echo -e "${BLUE}🔑 Regenerate Authelia password hashes:${NC}"
echo "  docker run --rm authelia/authelia:latest \\"
echo "    authelia crypto hash generate argon2 --password 'NEW_PASSWORD'"
echo ""
echo -e "${GREEN}Enjoy your AI-powered personal cloud! 🚀${NC}"
