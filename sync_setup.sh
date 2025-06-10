#!/bin/bash

# Script to set up local development with file sync to container

APP_NAME=$1

if [ -z "$APP_NAME" ]; then
    echo "Usage: $0 <app_name>"
    echo "Example: $0 my_custom_app"
    exit 1
fi

echo "🚀 Setting up local development for app: $APP_NAME"

# Step 1: Create the app in container
echo "📦 Creating app in container..."
docker exec -it frappe_docker-dev-tools-1 bash -c "
    cd /home/frappe/frappe-bench && \
    bench new-app $APP_NAME --no-git && \
    bench --site frontend install-app $APP_NAME && \
    bench migrate
"

if [ $? -ne 0 ]; then
    echo "❌ Failed to create app in container"
    exit 1
fi

# Step 2: Copy app to local directory
echo "📂 Copying app to local directory..."
mkdir -p "./local_apps"
docker cp frappe_docker-dev-tools-1:/home/frappe/frappe-bench/apps/$APP_NAME ./local_apps/

echo "✅ App copied to ./local_apps/$APP_NAME"

# Step 3: Create sync script
cat > "sync_${APP_NAME}.sh" << EOF
#!/bin/bash
# Auto-sync script for $APP_NAME

echo "🔄 Syncing $APP_NAME to container..."

# Copy local changes to container
docker cp ./local_apps/$APP_NAME/. frappe_docker-dev-tools-1:/home/frappe/frappe-bench/apps/$APP_NAME/

# Fix permissions
docker exec frappe_docker-dev-tools-1 chown -R frappe:frappe /home/frappe/frappe-bench/apps/$APP_NAME

# Restart bench to reload changes
docker exec frappe_docker-dev-tools-1 bash -c "cd /home/frappe/frappe-bench && bench restart"

echo "✅ Sync complete!"
EOF

chmod +x "sync_${APP_NAME}.sh"

# Step 4: Create VS Code workspace
cat > "${APP_NAME}_workspace.code-workspace" << EOF
{
    "folders": [
        {
            "name": "$APP_NAME",
            "path": "./local_apps/$APP_NAME"
        },
        {
            "name": "Project Root",
            "path": "."
        }
    ],
    "settings": {
        "python.defaultInterpreterPath": "/usr/local/bin/python",
        "python.linting.enabled": true,
        "python.linting.flake8Enabled": true,
        "python.formatting.provider": "black"
    },
    "extensions": {
        "recommendations": [
            "ms-python.python",
            "ms-python.debugpy",
            "ms-python.black-formatter",
            "ms-python.flake8"
        ]
    },
    "tasks": {
        "version": "2.0.0",
        "tasks": [
            {
                "label": "Sync to Container",
                "type": "shell",
                "command": "./sync_${APP_NAME}.sh",
                "group": "build",
                "presentation": {
                    "echo": true,
                    "reveal": "always",
                    "focus": false,
                    "panel": "shared"
                }
            },
            {
                "label": "Enter Container",
                "type": "shell",
                "command": "docker exec -it frappe_docker-dev-tools-1 bash",
                "group": "build",
                "presentation": {
                    "echo": true,
                    "reveal": "always",
                    "focus": true,
                    "panel": "new"
                }
            }
        ]
    }
}
EOF

echo ""
echo "🎉 Setup Complete!"
echo ""
echo "📁 Your app is available at: ./local_apps/$APP_NAME"
echo "🔄 Sync script created: ./sync_${APP_NAME}.sh"
echo "💼 VS Code workspace: ./${APP_NAME}_workspace.code-workspace"
echo ""
echo "🚀 Next Steps:"
echo "1. Open VS Code workspace:"
echo "   code ${APP_NAME}_workspace.code-workspace"
echo ""
echo "2. Edit your files in ./local_apps/$APP_NAME"
echo ""
echo "3. Sync changes to container:"
echo "   ./sync_${APP_NAME}.sh"
echo "   Or use VS Code task: Cmd+Shift+P -> Tasks: Run Task -> Sync to Container"
echo ""
echo "4. Access container terminal:"
echo "   docker exec -it frappe_docker-dev-tools-1 bash"
echo "   Or use VS Code task: Tasks: Run Task -> Enter Container"
echo ""
echo "5. Your Frappe site is available at: http://localhost:8090" 