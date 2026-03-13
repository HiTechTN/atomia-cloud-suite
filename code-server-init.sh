#!/bin/bash

# =============================================================================
# Code Server Init Script - Version 2.0
# Auto-installs Continue and custom extensions from remote URLs
# =============================================================================

set -e

echo "=========================================="
echo "Initializing Code Server..."
echo "=========================================="

# 1. Setup Continue Config
if [ -f /extension/continue/config.json ]; then
    mkdir -p ~/.continue
    cp /extension/continue/config.json ~/.continue/config.json
    echo "✓ Continue configuration applied"
fi

# 2. Install Extensions from URLs
# Expects a comma-separated list of URLs in EXTENSION_URLS env var
if [ -n "$EXTENSION_URLS" ]; then
    echo "Installing custom extensions..."
    mkdir -p /tmp/extensions
    
    IFS=',' read -ra ADDR <<< "$EXTENSION_URLS"
    for url in "${ADDR[@]}"; do
        filename=$(basename "$url")
        echo "Downloading $filename..."
        curl -L "$url" -o "/tmp/extensions/$filename"
        echo "Installing $filename..."
        code-server --install-extension "/tmp/extensions/$filename" || echo "Failed to install $filename"
    done
    
    rm -rf /tmp/extensions
    echo "✓ Custom extensions installed"
fi

# 3. Default Continue installation if not present
# (Marketplace installation as fallback)
if ! code-server --list-extensions | grep -q "continue"; then
    echo "Installing Continue extension from marketplace..."
    code-server --install-extension continue.continue || echo "Failed to install Continue"
fi

echo "✓ Code Server initialization complete"

# Start the actual code-server
exec /usr/bin/code-server --bind-addr 0.0.0.0:8080 --auth password /projects
