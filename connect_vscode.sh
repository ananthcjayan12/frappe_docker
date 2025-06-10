#!/bin/bash

# Script to connect VS Code to Frappe development container
# This bypasses devcontainer issues on ARM64

echo "🔧 Setting up VS Code connection to Frappe container..."

# Get container ID
CONTAINER_ID=$(docker ps -q --filter "name=frappe_docker-dev-tools-1")

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ Container frappe_docker-dev-tools-1 is not running!"
    echo "Start it with: docker-compose -f pwd.yml -f docker-compose.dev.yml up -d dev-tools"
    exit 1
fi

echo "✅ Found container: $CONTAINER_ID"

# Create a temporary workspace directory in the container
docker exec $CONTAINER_ID bash -c "mkdir -p /tmp/vscode-workspace"

# Method 1: Use Docker Desktop integration (if available)
echo "🚀 Attempting to open VS Code..."

# For VS Code with Docker extension
if command -v code >/dev/null 2>&1; then
    echo "Opening VS Code with Docker extension..."
    code --folder-uri "vscode-remote://attached-container+$(printf '%s' "$CONTAINER_ID" | xxd -p | tr -d '\n')/home/frappe/frappe-bench"
else
    echo "VS Code 'code' command not found in PATH"
fi

echo ""
echo "📝 Manual Steps if automatic opening failed:"
echo "1. Open VS Code"
echo "2. Install 'Docker' extension (ms-azuretools.vscode-docker)"
echo "3. Open Command Palette (Cmd+Shift+P)"
echo "4. Type 'Docker: Attach Visual Studio Code'"
echo "5. Select container: frappe_docker-dev-tools-1"
echo "6. Choose folder: /home/frappe/frappe-bench"
echo ""
echo "🔗 Container Details:"
echo "   Name: frappe_docker-dev-tools-1"
echo "   ID: $CONTAINER_ID"
echo "   Workspace: /home/frappe/frappe-bench"
echo ""
echo "🎯 Alternative: Terminal Access"
echo "   docker exec -it frappe_docker-dev-tools-1 bash" 