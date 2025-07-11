#!/usr/bin/env bash
set -e

# Project and compose definitions
STACK_NAME=frappe_docker
COMPOSE_FILE=pwd.yml

# Named volumes used by pwd.yml
SITES_VOLUME="${STACK_NAME}_sites"
ASSETS_VOLUME="${STACK_NAME}_sites_assets"
LOGS_VOLUME="${STACK_NAME}_logs"

echo "Stopping existing stack..."
docker compose -p "$STACK_NAME" -f "$COMPOSE_FILE" down

echo "Removing stale assets volume (if exists): $ASSETS_VOLUME"
docker volume rm -f "$ASSETS_VOLUME" || true

echo "Re-starting stack..."
docker compose -p "$STACK_NAME" -f "$COMPOSE_FILE" up -d

echo "Clearing bench cache on backend container..."
docker compose -p "$STACK_NAME" exec backend bench --site frontend clear-cache

echo "Redeploy complete (stack: $STACK_NAME)." 