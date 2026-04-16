#!/bin/bash

# =============================================================================
# SSH Setup Script for Code Server
# Connect to remote Code Server from local VS Code
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  SSH Setup for Code Server${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

# ── Check Dependencies ─────────────────────────────────────────────────────────
if ! command -v ssh-keygen &>/dev/null; then
    echo -e "${RED}Error: ssh-keygen is not installed.${NC}"
    exit 1
fi

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')
SSH_PORT=2222

echo ""
echo -e "${YELLOW}Server Information:${NC}"
echo "  • IP Address: $SERVER_IP"
echo "  • SSH Port: $SSH_PORT"
echo "  • Username: coder"
echo ""

# Check if SSH keys exist
SSH_KEY_PATH="./data/code-server-ssh"

if [ ! -d "$SSH_KEY_PATH" ]; then
    mkdir -p "$SSH_KEY_PATH"
fi

# Generate SSH key if not exists
if [ ! -f "$SSH_KEY_PATH/id_rsa" ]; then
    echo -e "${YELLOW}Generating SSH key pair...${NC}"
    ssh-keygen -t rsa -b 4096 -f "$SSH_KEY_PATH/id_rsa" -N "" -C "code-server@atomia"
    echo -e "${GREEN}✓ SSH key generated${NC}"
else
    echo -e "${GREEN}✓ SSH key already exists${NC}"
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Connection Instructions${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Display public key
echo -e "${YELLOW}Public Key (add to ~/.ssh/known_hosts):${NC}"
echo ""
cat "$SSH_KEY_PATH/id_rsa.pub"
echo ""

echo ""
echo -e "${GREEN}To connect from local VS Code:${NC}"
echo ""
echo "1. Install 'Remote - SSH' extension in VS Code"
echo ""
echo "2. Add this to your local ~/.ssh/config:"
echo ""
echo "   Host atomia-code-server"
echo "       HostName $SERVER_IP"
echo "       Port $SSH_PORT"
echo "       User coder"
echo "       IdentityFile ~/.ssh/id_rsa"
echo ""
echo "3. Or connect directly:"
echo "   ssh -p $SSH_PORT coder@$SERVER_IP"
echo ""

# Test SSH connection
echo -e "${YELLOW}Testing SSH connection...${NC}"
if command -v nc &> /dev/null; then
    if nc -z localhost $SSH_PORT 2>/dev/null; then
        echo -e "${GREEN}✓ SSH service is running on port $SSH_PORT${NC}"
    else
        echo -e "${RED}✗ SSH service not running on port $SSH_PORT${NC}"
        echo "  Make sure docker-compose is running"
    fi
else
    echo "  (nc not available for testing)"
fi

echo ""
echo -e "${GREEN}Setup complete!${NC}"
