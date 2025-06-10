# Custom Frappe App Development Guide

This guide explains how to create and debug custom Frappe apps using your existing production setup.

## Quick Start

### 1. Create a Custom App

```bash
./create_custom_app.sh my_custom_app
```

### 2. Connect VS Code to Container

**Option A: Attach to Running Container**
1. Press `Cmd+Shift+P` (or `Ctrl+Shift+P` on Windows/Linux)
2. Type "Remote-Containers: Attach to Running Container"
3. Select `frappe_docker-dev-tools-1`
4. Open folder: `/home/frappe/frappe-bench/apps/your_app_name`

**Option B: Use Custom DevContainer**
1. Copy the custom devcontainer config:
   ```bash
   cp -r .devcontainer-custom .devcontainer
   ```
2. Press `Cmd+Shift+P`
3. Type "Remote-Containers: Reopen in Container"

## Development Workflow

### Creating Apps
```bash
# Inside the dev-tools container
bench new-app my_app --no-git
bench --site frontend install-app my_app
bench migrate
```

### Running Development Server
```bash
# Inside container
bench start
# Or for debugging
bench serve --port 8000 --host 0.0.0.0
```

### Debugging with VS Code

1. **Python Debugging**:
   - Create `.vscode/launch.json` in your app directory
   - Add Python debugging configuration
   - Set breakpoints in your Python code

2. **JavaScript Debugging**:
   - Use browser dev tools
   - Source maps are available for debugging

### Useful Commands

```bash
# Enter development container
docker exec -it frappe_docker-dev-tools-1 bash

# Restart services after code changes
bench restart

# Watch for changes and auto-reload
bench watch

# Database migrations
bench migrate

# Clear cache
bench clear-cache

# Install new DocTypes
bench --site frontend migrate
```

## File Structure

```
/home/frappe/frappe-bench/
├── apps/
│   ├── frappe/          # Core Frappe framework
│   ├── erpnext/         # ERPNext app
│   └── your_app/        # Your custom app
├── sites/
│   └── frontend/        # Your site
└── logs/
```

## Ports

- **8000**: Direct backend access (dev server)
- **8080**: Additional debugging port
- **8090**: Frontend (nginx) - from production setup
- **9000**: WebSocket server

## Tips

1. **Code Synchronization**: Use VS Code's file sync to keep your local files in sync with container files

2. **Database Access**: Connect to MariaDB using:
   - Host: localhost (from container)
   - Port: 3306
   - User: root
   - Password: admin

3. **Redis Access**: Available at `redis-cache:6379` and `redis-queue:6379`

4. **Log Monitoring**:
   ```bash
   # Inside container
   tail -f /home/frappe/frappe-bench/logs/web.log
   ```

5. **Hot Reload**: The development server supports hot reload for Python changes

## Troubleshooting

### Container Issues
```bash
# Restart dev container
docker-compose -f pwd.yml -f docker-compose.dev.yml restart dev-tools

# Check container logs
docker logs frappe_docker-dev-tools-1
```

### App Installation Issues
```bash
# Inside container
bench --site frontend list-apps  # List installed apps
bench --site frontend uninstall-app my_app  # Uninstall if needed
bench --site frontend install-app my_app  # Reinstall
```

### Permission Issues
```bash
# Fix permissions inside container
sudo chown -R frappe:frappe /home/frappe/frappe-bench/apps/your_app
```

## Advanced Development

### Custom DocTypes
1. Create DocType in your app
2. Run `bench migrate` to create database tables
3. Customize forms and views as needed

### API Development
- Create REST APIs in your app
- Test using the built-in API browser at `/api/method/your_app.api.method_name`

### Custom Scripts
- Add custom JavaScript in DocType customizations
- Use client scripts for dynamic behavior

## Production Deployment

When ready to deploy:
1. Create a proper production image with your custom app
2. Update your docker-compose files to include the custom app
3. Run migrations on production site 