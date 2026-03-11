#!/bin/bash

# =============================================================================
# Code Server Init Script - Install Continue Extension
# This script runs when the code-server container starts
# =============================================================================

set -e

echo "=========================================="
echo "Initializing Code Server with Continue..."
echo "=========================================="

# Wait for code-server to be ready
sleep 5

# Install Continue extension from VSIX (alternative to marketplace)
# The extension will auto-connect to Ollama via the config.json we mount

# Alternative: If you want to install from marketplace (requires internet)
# Replace with your marketplace extension if needed

# Copy Continue config
if [ -f /extension/continue/config.json ]; then
    mkdir -p ~/.continue
    cp /extension/continue/config.json ~/.continue/config.json
    echo "✓ Continue config copied"
fi

# Create extension install script for manual install
cat > ~/.continue/install-extension.sh << 'EOF'
#!/bin/bash
# Manual extension installation for Continue
# Run this inside Code Server terminal if needed

# Method 1: Install from Open VSX (recommended)
code-server --install-extension https://open-vsx.org/api/Continue/Continue/1.9.129/file/Continue-1.9.129.vsix

# Method 2: Or install from local file
# code-server --install-extension /path/to/continue.vsix
EOF

chmod +x ~/.continue/install-extension.sh

echo "✓ Code Server initialization complete"
echo "To install Continue extension manually, run:"
echo "  ~/.continue/install-extension.sh"
echo ""
echo "Or search for 'Continue' in the Code Server extensions marketplace"
