#!/bin/bash

# =============================================================================
# ATOMIA CLOUD SUITE - Setup Script
# Auto-install Docker, Docker Compose, and download initial AI models
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  ATOMIA CLOUD SUITE - Setup Script${NC}"
echo -e "${BLUE}  Your Personal AI-Powered Development Environment${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# =============================================================================
# STEP 1: Check and Install Docker
# =============================================================================
echo -e "${YELLOW}[1/5] Checking Docker installation...${NC}"

if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓ Docker is already installed: $(docker --version)${NC}"
else
    echo -e "${YELLOW}Installing Docker...${NC}"
    
    # Detect OS
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "${YELLOW}Running Docker installation script...${NC}"
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        rm get-docker.sh
        
        # Add user to docker group
        sudo usermod -aG docker $USER
        echo -e "${GREEN}✓ Docker installed successfully${NC}"
    else
        echo -e "${RED}Please run this script as non-root user after Docker is installed${NC}"
        exit 1
    fi
fi

# =============================================================================
# STEP 2: Check and Install Docker Compose
# =============================================================================
echo -e "${YELLOW}[2/5] Checking Docker Compose...${NC}"

if command -v docker compose &> /dev/null; then
    echo -e "${GREEN}✓ Docker Compose is available: $(docker compose version)${NC}"
elif command -v docker-compose &> /dev/null; then
    echo -e "${GREEN}✓ Docker Compose is available: $(docker-compose version)${NC}"
else
    echo -e "${RED}Docker Compose is not installed. Please install Docker Compose manually.${NC}"
    exit 1
fi

# =============================================================================
# STEP 3: Check NVIDIA GPU Support (Optional)
# =============================================================================
echo -e "${YELLOW}[3/5] Checking GPU support...${NC}"

if command -v nvidia-smi &> /dev/null; then
    echo -e "${GREEN}✓ NVIDIA GPU detected!${NC}"
    nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
    echo -e "${GREEN}✓ Ollama will use GPU acceleration${NC}"
else
    echo -e "${YELLOW}⚠ No NVIDIA GPU detected. Running in CPU mode.${NC}"
    echo -e "${YELLOW}  Install NVIDIA Container Toolkit for GPU support:${NC}"
    echo -e "${YELLOW}  https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html${NC}"
fi

# =============================================================================
# STEP 4: Create Docker Network and Data Directories
# =============================================================================
echo -e "${YELLOW}[4/5] Creating Docker network and data directories...${NC}"

# Create data directories for persistent storage
mkdir -p data/ollama
mkdir -p data/openwebui
mkdir -p data/code-server
mkdir -p data/gitea
mkdir -p data/gitea-ssh
mkdir -p data/qdrant
mkdir -p data/prometheus
mkdir -p data/grafana
mkdir -p monitoring
mkdir -p backups
mkdir -p projects
mkdir -p continue

echo -e "${GREEN}✓ Data directories created${NC}"

docker network create atomia-network 2>/dev/null || echo "Network already exists"

# =============================================================================
# STEP 5: Pull Docker Images
# =============================================================================
echo -e "${YELLOW}[5/5] Pulling Docker images (this may take a while)...${NC}"

echo "Pulling Ollama..."
docker pull ollama/ollama:latest

echo "Pulling Open WebUI..."
docker pull ghcr.io/open-webui/open-webui:main

echo "Pulling Code Server..."
docker pull codercom/code-server:latest

echo "Pulling Gitea..."
docker pull gitea/gitea:latest

echo "Pulling Gitea Runner..."
docker pull gitea/act_runner:latest

echo "Pulling Qdrant (Vector Database for RAG)..."
docker pull qdrant/qdrant:latest

echo "Pulling Monitoring Stack (Prometheus, Grafana, cAdvisor)..."
docker pull prom/prometheus:latest
docker pull grafana/grafana:latest
docker pull gcr.io/cadvisor/cadvisor:latest

# Optional: Nginx Proxy Manager
# echo "Pulling Nginx Proxy Manager..."
# docker pull jc21/nginx-proxy-manager:latest

echo -e "${GREEN}✓ All images pulled successfully${NC}"

# =============================================================================
# Download Initial AI Models
# =============================================================================
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Downloading Initial AI Models (Optional)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

read -p "Download initial AI models now? (recommended) [Y/n]: " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
    # Start Ollama temporarily to download models
    echo -e "${YELLOW}Starting Ollama temporarily to download models...${NC}"
    
    # Run Ollama in background
    docker run -d --name atomia-ollama-setup \
        -v atomia-ollama-data:/models \
        -p 11434:11434 \
        ollama/ollama:latest
    
    # Wait for Ollama to be ready
    echo "Waiting for Ollama to start..."
    sleep 10
    
    # Download models
    echo -e "${GREEN}Downloading CodeLlama (7B - good balance of speed and quality)...${NC}"
    docker exec atomia-ollama-setup ollama pull codellama
    
    echo -e "${GREEN}Downloading DeepSeek Coder (excellent for code generation)...${NC}"
    docker exec atomia-ollama-setup ollama pull deepseek-coder
    
    echo -e "${GREEN}Downloading Llama 3 (general purpose)...${NC}"
    docker exec atomia-ollama-setup ollama pull llama3
    
    echo -e "${GREEN}Downloading Mistral (fast and efficient)...${NC}"
    docker exec atomia-ollama-setup ollama pull mistral
    
    echo -e "${GREEN}Downloading nomic-embed-text (for code embeddings)...${NC}"
    docker exec atomia-ollama-setup ollama pull nomic-embed-text
    
    # Stop temporary container
    docker stop atomia-ollama-setup
    docker rm atomia-ollama-setup
    
    echo -e "${GREEN}✓ Initial models downloaded${NC}"
else
    echo -e "${YELLOW}Skipping model download. You can do this later with:${NC}"
    echo "  docker exec atomia-ollama ollama pull <model-name>"
fi

# =============================================================================
# Start All Services
# =============================================================================
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Starting Atomia Cloud Suite${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

docker compose up -d

# =============================================================================
# Wait for services to be healthy
# =============================================================================
echo "Waiting for services to start..."
sleep 15

# =============================================================================
# Display Access Information
# =============================================================================
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✓ ATOMIA CLOUD SUITE IS NOW RUNNING!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}📍 Access URLs:${NC}"
echo -e "  • Open WebUI (Chat):    http://localhost:8080"
echo -e "  • Code Server (IDE):    http://localhost:8443"
echo -e "  • Gitea (Git Server):   http://localhost:3000"
echo -e "  • Ollama API:           http://localhost:11434"
echo -e "  • Grafana (Monitoring): http://localhost:3001"
echo -e "  • Nginx Proxy Manager:  http://localhost:81 (if enabled)"
echo ""
echo -e "${YELLOW}⚠️  Default Credentials:${NC}"
echo -e "  • Code Server:          password = 'change_this_password'"
echo -e "  • Gitea:                Username: admin, Password: change_this_password"
echo -e "  • Nginx Proxy Manager:   admin@example.com / changeme"
echo ""
echo -e "${BLUE}📝 Useful Commands:${NC}"
echo "  docker compose logs -f        # View logs"
echo "  docker compose restart        # Restart all services"
echo "  docker compose down           # Stop all services"
echo "  docker compose logs -f ollama # View Ollama logs"
echo "  docker compose logs -f gitea  # View Gitea logs"
echo ""
echo -e "${GREEN}Enjoy your AI-powered development environment! 🚀${NC}"
