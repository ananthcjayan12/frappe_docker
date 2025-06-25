# Port Management System

This system helps you manage port allocations for your Coolify deployment and multitenancy setup.

## Files

- `port-allocation.csv` - Master list of all ports and their allocation status
- `port-manager.sh` - Management script for port operations
- `multitenancy.env` - Environment configuration for multitenancy setup

## Current Port Allocations for Frappe Multitenancy

Based on your Coolify setup, the following ports have been allocated for multitenancy:

| Tenant | Port | URL |
|--------|------|-----|
| Tenant 1 | 8096 | http://localhost:8096 |
| Tenant 2 | 8097 | http://localhost:8097 |
| Tenant 3 | 8098 | http://localhost:8098 |

## Port Manager Usage

### Quick Start

```bash
# Make the script executable (already done)
chmod +x port-manager.sh

# View current status
./port-manager.sh status

# List all ports
./port-manager.sh list

# Show available ports only
./port-manager.sh available
```

### Common Operations

#### Find Available Ports
```bash
# Find next available port
./port-manager.sh find

# Find next 5 available ports
./port-manager.sh find 5
```

#### Allocate a Port
```bash
# Allocate a port for new tenant
./port-manager.sh allocate 8099 "Frappe Frontend" "tenant4" "New customer site"

# Allocate port for different service
./port-manager.sh allocate 8020 "Redis" "analytics" "Analytics Redis instance"
```

#### Free a Port
```bash
# Free up a port when service is decommissioned
./port-manager.sh free 8099
```

#### Backup Management
```bash
# Create backup before major changes
./port-manager.sh backup

# Restore from backup if needed
./port-manager.sh restore
```

## Adding New Tenants

### Option 1: Use Available Ports

1. Find available port:
   ```bash
   ./port-manager.sh find
   ```

2. Allocate the port:
   ```bash
   ./port-manager.sh allocate 8020 "Frappe Frontend" "tenant4" "New tenant"
   ```

3. Update your compose file with the new tenant:
   ```yaml
   frontend-tenant4:
     image: frappe/erpnext:v15.64.1
     networks:
       - frappe_network
     depends_on:
       - websocket
     deploy:
       restart_policy:
         condition: on-failure
     command:
       - nginx-entrypoint.sh
     environment:
       BACKEND: backend:8000
       FRAPPE_SITE_NAME_HEADER: tenant4.localhost
       SOCKETIO: websocket:9000
       # ... other environment variables
     volumes:
       - sites:/home/frappe/frappe-bench/sites
       - logs:/home/frappe/frappe-bench/logs
     ports:
       - "8020:8080"  # Use the allocated port
   ```

### Option 2: Use Predefined Multitenancy Setup

Use the `pwd-multitenancy.yml` file which already has ports allocated:

```bash
# Start the predefined multitenancy setup
docker compose -f pwd-multitenancy.yml up -d

# Access tenants at:
# - http://localhost:8096 (tenant1.localhost)
# - http://localhost:8097 (tenant2.localhost) 
# - http://localhost:8098 (tenant3.localhost)
```

## Port Ranges

The system tracks ports in these ranges:

### Allocated (Coolify System):
- 80, 443 (HTTP/HTTPS)
- 3000, 3101 (Various services)
- 5001, 5432, 5555 (Database/services)
- 6001-6002, 6379, 6380 (Redis/services)
- 8000, 8001, 8010, 8030, 8040, 8080, 8090, 8095 (HTTP services)

### Available for Allocation:
- 8020-8029, 8031-8039, 8041-8094, 8096-8099
- 9001-9010 (and more)

## Conflict Resolution

If you encounter port conflicts:

1. Check current allocations:
   ```bash
   ./port-manager.sh allocated
   ```

2. Find the conflicting service:
   ```bash
   docker ps --format "table {{.Names}}\t{{.Ports}}"
   ```

3. Either:
   - Free the port if service is no longer needed
   - Use a different available port
   - Update the conflicting service to use a different port

## Monitoring

### Check Port Usage
```bash
# System-wide port usage
netstat -tuln | grep LISTEN

# Docker container ports
docker ps --format "table {{.Names}}\t{{.Ports}}"

# Port manager status
./port-manager.sh status
```

### Regular Maintenance

1. **Weekly**: Run `./port-manager.sh status` to review allocations
2. **Before major deployments**: Create backup with `./port-manager.sh backup`
3. **After service removal**: Free ports with `./port-manager.sh free <port>`

## Integration with Coolify

When deploying services in Coolify:

1. Check available ports: `./port-manager.sh find`
2. Allocate port: `./port-manager.sh allocate <port> <service> <project>`
3. Use the allocated port in your Coolify service configuration
4. Document the allocation in your deployment notes

## Troubleshooting

### Port Already in Use
```bash
# Check what's using the port
lsof -i :8096

# Or use netstat
netstat -tuln | grep 8096
```

### CSV File Issues
```bash
# Restore from backup
./port-manager.sh restore

# Or recreate from scratch (you'll lose history)
cp port-allocation.csv port-allocation.backup.csv
# Edit manually or regenerate
```

### Script Permissions
```bash
# Make sure script is executable
chmod +x port-manager.sh

# Check current permissions
ls -la port-manager.sh
```

## Best Practices

1. **Always check available ports before manual allocation**
2. **Use the port manager for all allocations to maintain consistency**
3. **Create backups before major changes**
4. **Document the purpose of each port allocation**
5. **Regular cleanup of unused port allocations**
6. **Use consistent naming for services and projects**

## Examples

### Complete Tenant Addition Workflow

```bash
# 1. Check current status
./port-manager.sh status

# 2. Find available port
AVAILABLE_PORT=$(./port-manager.sh find 1 | grep "Port:" | cut -d' ' -f2)
echo "Available port: $AVAILABLE_PORT"

# 3. Allocate port
./port-manager.sh allocate $AVAILABLE_PORT "Frappe Frontend" "tenant4" "New customer: ACME Corp"

# 4. Update compose file with new tenant service
# 5. Deploy with docker compose

# 6. Verify deployment
curl -I http://localhost:$AVAILABLE_PORT
```

This system ensures you never have port conflicts and maintains a clear record of all port allocations across your infrastructure. 