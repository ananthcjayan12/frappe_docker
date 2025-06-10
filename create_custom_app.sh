#!/bin/bash

# Script to create a custom Frappe app in development environment

APP_NAME=$1

if [ -z "$APP_NAME" ]; then
    echo "Usage: $0 <app_name>"
    echo "Example: $0 my_custom_app"
    exit 1
fi

echo "Creating custom Frappe app: $APP_NAME"

# Create the app using bench in dev-tools container
docker exec -it frappe_docker-dev-tools-1 bash -c "
    cd /home/frappe/frappe-bench && \
    bench new-app $APP_NAME --no-git && \
    bench --site frontend install-app $APP_NAME && \
    bench migrate
"

if [ $? -eq 0 ]; then
    echo "✅ Successfully created app: $APP_NAME"
    echo "📁 App location: /home/frappe/frappe-bench/apps/$APP_NAME"
    echo "🔧 You can now connect VS Code to the container for development"
    echo ""
    echo "Next steps:"
    echo "1. Copy app to local directory for editing:"
    echo "   docker cp frappe_docker-dev-tools-1:/home/frappe/frappe-bench/apps/$APP_NAME ./custom_apps/"
    echo ""
    echo "2. Open VS Code in container:"
    echo "   - Press Cmd+Shift+P"
    echo "   - Type 'Remote-Containers: Attach to Running Container'"
    echo "   - Select 'frappe_docker-dev-tools-1'"
    echo ""
    echo "3. Or use our custom devcontainer:"
    echo "   - Copy .devcontainer-custom to .devcontainer"
    echo "   - Reopen in container"
else
    echo "❌ Failed to create app: $APP_NAME"
    exit 1
fi 