# Multitenancy Guide for Frappe Docker

This guide explains how to implement multitenancy in your ERPNext setup using Docker Compose.

## Overview

There are three main approaches to implement multitenancy:

1. **Single Bench, Multiple Sites** (Simplest)
2. **Port-based Multitenancy** (Medium complexity)
3. **Multi-Bench with Traefik** (Most advanced, like Single Server Example)

## Approach 1: Single Bench, Multiple Sites

Your modified `pwd.yml` now supports this approach. It creates multiple sites within a single bench.

### Usage:

```bash
# Start the services
docker compose -f pwd.yml up -d

# Access different sites:
# - tenant1.localhost:8095
# - tenant2.localhost:8095  
# - tenant3.localhost:8095
```

### Adding your hosts (required for localhost access):

Add these lines to your `/etc/hosts` file (Mac/Linux) or `C:\Windows\System32\drivers\etc\hosts` (Windows):

```
127.0.0.1 tenant1.localhost
127.0.0.1 tenant2.localhost
127.0.0.1 tenant3.localhost
```

### Creating additional sites:

```bash
# Access the backend container
docker compose -f pwd.yml exec backend bash

# Create a new site
bench new-site --mariadb-user-host-login-scope='%' --admin-password=admin --db-root-username=root --db-root-password=admin --install-app erpnext new-tenant.localhost
```

## Approach 2: Port-based Multitenancy

Use the `pwd-multitenancy.yml` file for this approach. Each tenant gets their own port.

### Usage:

```bash
# Start the services
docker compose -f pwd-multitenancy.yml up -d

# Access different tenants:
# - Tenant 1: http://localhost:8095
# - Tenant 2: http://localhost:8096  
# - Tenant 3: http://localhost:8097
```

### Benefits:
- Each tenant has isolated frontend
- Easy to manage different configurations per tenant
- Better resource allocation

## Approach 3: Multi-Bench Setup (Advanced)

This follows the Single Server Example pattern you provided. For production environments with multiple benches.

### Prerequisites:

1. Install Traefik:
```bash
# Create gitops directory
mkdir ~/gitops

# Create traefik.env
echo 'TRAEFIK_DOMAIN=traefik.example.com' > ~/gitops/traefik.env
echo 'EMAIL=admin@example.com' >> ~/gitops/traefik.env
echo 'HASHED_PASSWORD='$(openssl passwd -apr1 changeit | sed -e s/\\$/\\$\\$/g) >> ~/gitops/traefik.env

# Deploy traefik
docker compose --project-name traefik \
  --env-file ~/gitops/traefik.env \
  -f overrides/compose.traefik.yaml \
  -f overrides/compose.traefik-ssl.yaml up -d
```

2. Install shared MariaDB:
```bash
echo "DB_PASSWORD=changeit" > ~/gitops/mariadb.env
docker compose --project-name mariadb --env-file ~/gitops/mariadb.env -f overrides/compose.mariadb-shared.yaml up -d
```

3. Create bench configurations:
```bash
# Create first bench
cp example.env ~/gitops/erpnext-one.env
sed -i 's/DB_PASSWORD=123/DB_PASSWORD=changeit/g' ~/gitops/erpnext-one.env
sed -i 's/DB_HOST=/DB_HOST=mariadb-database/g' ~/gitops/erpnext-one.env
sed -i 's/DB_PORT=/DB_PORT=3306/g' ~/gitops/erpnext-one.env
sed -i 's/SITES=`erp.example.com`/SITES=\`one.example.com\`,\`two.example.com\`/g' ~/gitops/erpnext-one.env
echo 'ROUTER=erpnext-one' >> ~/gitops/erpnext-one.env
echo "BENCH_NETWORK=erpnext-one" >> ~/gitops/erpnext-one.env

# Generate compose file
docker compose --project-name erpnext-one \
  --env-file ~/gitops/erpnext-one.env \
  -f compose.yaml \
  -f overrides/compose.redis.yaml \
  -f overrides/compose.multi-bench.yaml \
  -f overrides/compose.multi-bench-ssl.yaml config > ~/gitops/erpnext-one.yaml

# Deploy
docker compose --project-name erpnext-one -f ~/gitops/erpnext-one.yaml up -d
```

## Site Operations

### Add new site to existing bench:
```bash
docker compose exec backend bench new-site --mariadb-user-host-login-scope='%' --admin-password=admin --db-root-password=admin --install-app erpnext new-site.localhost
```

### List all sites:
```bash
docker compose exec backend bench list-sites
```

### Backup site:
```bash
docker compose exec backend bench backup --site=site-name.localhost
```

### Restore site:
```bash
docker compose exec backend bench restore backup-file.sql --site=site-name.localhost
```

### Site maintenance:
```bash
# Enable maintenance mode
docker compose exec backend bench set-maintenance-mode on --site=site-name.localhost

# Disable maintenance mode  
docker compose exec backend bench set-maintenance-mode off --site=site-name.localhost
```

## Configuration Options

### Environment Variables

You can use the `multitenancy.env` file to configure:

- `TENANT_SITES`: Comma-separated list of tenant sites
- `ADMIN_PASSWORD`: Admin password for all sites
- `DB_ROOT_PASSWORD`: Database root password
- Port mappings for different tenants

### Custom Apps

To install custom apps on specific sites:

```bash
# Install app on specific site
docker compose exec backend bench install-app custom-app --site=tenant1.localhost

# Install app on all sites
docker compose exec backend bench install-app custom-app
```

## Security Considerations

1. **Database Isolation**: Each site has its own database
2. **File Isolation**: Sites share the same file system but have separate directories
3. **User Isolation**: Users from one site cannot access another site
4. **Session Isolation**: Sessions are isolated per site

## Monitoring and Logs

### View logs:
```bash
# Backend logs
docker compose logs backend

# Site-specific logs
docker compose exec backend tail -f /home/frappe/frappe-bench/logs/site-name.localhost.log
```

### Resource monitoring:
```bash
# Container resource usage
docker stats

# Site-specific resource usage
docker compose exec backend bench doctor
```

## Troubleshooting

### Common Issues:

1. **Site not accessible**: Check if the site exists and is in the hosts file
2. **Database connection errors**: Verify MariaDB is running and passwords are correct
3. **File permission issues**: Ensure proper volume permissions

### Debug commands:
```bash
# Check site status
docker compose exec backend bench show-config

# Test database connectivity
docker compose exec backend bench console

# Check nginx configuration
docker compose exec frontend nginx -t
```

## Performance Optimization

### For better performance:
1. Use separate Redis instances for cache and queue
2. Configure proper worker processes
3. Use CDN for static assets
4. Implement database connection pooling
5. Monitor resource usage and scale accordingly

Choose the approach that best fits your needs:
- **Approach 1** for simple setups and development
- **Approach 2** for better tenant isolation
- **Approach 3** for production environments with complex requirements 