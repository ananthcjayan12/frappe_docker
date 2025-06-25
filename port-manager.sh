#!/bin/bash

# Port Manager Script for Coolify/Frappe Docker
# Usage: ./port-manager.sh [command] [options]

CSV_FILE="port-allocation.csv"
BACKUP_FILE="port-allocation.backup.csv"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display usage
show_usage() {
    echo "Port Manager - Coolify/Frappe Docker Port Allocation Tool"
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  list                    List all ports and their status"
    echo "  available               Show only available ports"
    echo "  allocated               Show only allocated ports"
    echo "  allocate <port> <service> <project> [notes]"
    echo "                         Allocate a port to a service"
    echo "  free <port>            Free up an allocated port"
    echo "  find <count>           Find next available ports (default: 1)"
    echo "  backup                 Create backup of current allocation"
    echo "  restore                Restore from backup"
    echo "  status                 Show allocation summary"
    echo ""
    echo "Examples:"
    echo "  $0 list"
    echo "  $0 available"
    echo "  $0 allocate 8099 \"Frappe Frontend\" \"tenant4\" \"New tenant site\""
    echo "  $0 free 8099"
    echo "  $0 find 3"
    echo ""
}

# Function to check if CSV file exists
check_csv() {
    if [[ ! -f "$CSV_FILE" ]]; then
        echo -e "${RED}Error: $CSV_FILE not found!${NC}"
        echo "Please make sure the port-allocation.csv file exists."
        exit 1
    fi
}

# Function to list ports
list_ports() {
    check_csv
    echo -e "${BLUE}Port Allocation Status:${NC}"
    echo ""
    column -t -s',' "$CSV_FILE"
}

# Function to show available ports
show_available() {
    check_csv
    echo -e "${GREEN}Available Ports:${NC}"
    echo ""
    grep "AVAILABLE" "$CSV_FILE" | column -t -s','
}

# Function to show allocated ports
show_allocated() {
    check_csv
    echo -e "${YELLOW}Allocated Ports:${NC}"
    echo ""
    grep "ALLOCATED" "$CSV_FILE" | column -t -s','
}

# Function to allocate a port
allocate_port() {
    local port=$1
    local service=$2
    local project=$3
    local notes=$4
    local date=$(date +%Y-%m-%d)
    
    if [[ -z "$port" || -z "$service" || -z "$project" ]]; then
        echo -e "${RED}Error: Port, service, and project are required!${NC}"
        echo "Usage: $0 allocate <port> <service> <project> [notes]"
        exit 1
    fi
    
    check_csv
    
    # Check if port is already allocated
    if grep -q "^$port,ALLOCATED" "$CSV_FILE"; then
        echo -e "${RED}Error: Port $port is already allocated!${NC}"
        grep "^$port," "$CSV_FILE" | column -t -s','
        exit 1
    fi
    
    # Check if port exists in available list
    if grep -q "^$port,AVAILABLE" "$CSV_FILE"; then
        # Update existing available port
        sed -i "s/^$port,AVAILABLE,,,Available for allocation,/$port,ALLOCATED,$service,$project,$notes,$date/" "$CSV_FILE"
        echo -e "${GREEN}✓ Port $port allocated to $service ($project)${NC}"
    else
        # Add new port as allocated
        echo "$port,ALLOCATED,$service,$project,$notes,$date" >> "$CSV_FILE"
        echo -e "${GREEN}✓ Port $port added and allocated to $service ($project)${NC}"
    fi
}

# Function to free a port
free_port() {
    local port=$1
    
    if [[ -z "$port" ]]; then
        echo -e "${RED}Error: Port number is required!${NC}"
        echo "Usage: $0 free <port>"
        exit 1
    fi
    
    check_csv
    
    # Check if port is allocated
    if ! grep -q "^$port,ALLOCATED" "$CSV_FILE"; then
        echo -e "${RED}Error: Port $port is not currently allocated!${NC}"
        exit 1
    fi
    
    # Free the port
    sed -i "s/^$port,ALLOCATED,.*/$port,AVAILABLE,,,Available for allocation,/" "$CSV_FILE"
    echo -e "${GREEN}✓ Port $port has been freed and is now available${NC}"
}

# Function to find available ports
find_available() {
    local count=${1:-1}
    
    check_csv
    
    echo -e "${BLUE}Next $count available ports:${NC}"
    echo ""
    grep "AVAILABLE" "$CSV_FILE" | head -n "$count" | cut -d',' -f1 | while read port; do
        echo "Port: $port"
    done
}

# Function to create backup
backup_csv() {
    check_csv
    cp "$CSV_FILE" "$BACKUP_FILE"
    echo -e "${GREEN}✓ Backup created: $BACKUP_FILE${NC}"
}

# Function to restore from backup
restore_csv() {
    if [[ ! -f "$BACKUP_FILE" ]]; then
        echo -e "${RED}Error: Backup file $BACKUP_FILE not found!${NC}"
        exit 1
    fi
    
    cp "$BACKUP_FILE" "$CSV_FILE"
    echo -e "${GREEN}✓ Restored from backup: $BACKUP_FILE${NC}"
}

# Function to show status summary
show_status() {
    check_csv
    
    local total=$(tail -n +2 "$CSV_FILE" | wc -l)
    local allocated=$(grep -c "ALLOCATED" "$CSV_FILE")
    local available=$(grep -c "AVAILABLE" "$CSV_FILE")
    
    echo -e "${BLUE}Port Allocation Summary:${NC}"
    echo "------------------------"
    echo "Total ports tracked: $total"
    echo -e "Allocated ports: ${YELLOW}$allocated${NC}"
    echo -e "Available ports: ${GREEN}$available${NC}"
    echo ""
    
    echo -e "${BLUE}Recently allocated ports:${NC}"
    grep "ALLOCATED" "$CSV_FILE" | tail -5 | column -t -s','
}

# Main script logic
case "$1" in
    "list")
        list_ports
        ;;
    "available")
        show_available
        ;;
    "allocated")
        show_allocated
        ;;
    "allocate")
        allocate_port "$2" "$3" "$4" "$5"
        ;;
    "free")
        free_port "$2"
        ;;
    "find")
        find_available "$2"
        ;;
    "backup")
        backup_csv
        ;;
    "restore")
        restore_csv
        ;;
    "status")
        show_status
        ;;
    *)
        show_usage
        ;;
esac 