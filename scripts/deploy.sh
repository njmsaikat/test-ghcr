#!/bin/bash
# Server Deployment Script for GHCR
# This script should be placed on your server in the deployment directory

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
COMPOSE_FILE="docker-compose.prod.yml"

echo -e "${GREEN}=== GHCR Deployment Update Script ===${NC}"
echo ""

# Check if docker-compose.prod.yml exists
if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "${RED}Error: $COMPOSE_FILE not found!${NC}"
    echo "Make sure you're in the correct directory."
    exit 1
fi

# Check if .env.prod exists
if [ ! -f ".env.prod" ]; then
    echo -e "${RED}Error: .env.prod not found!${NC}"
    echo "Create .env.prod file with your production configuration."
    exit 1
fi

# Function to backup database
backup_database() {
    echo -e "${YELLOW}Creating database backup...${NC}"
    BACKUP_FILE="backup_$(date +%Y%m%d_%H%M%S).sql"
    
    if docker compose -f "$COMPOSE_FILE" ps db | grep -q "Up"; then
        # Load DB credentials from .env.prod
        source .env.prod
        docker exec db pg_dump -U ${DB_USER} ${DB_NAME} > "$BACKUP_FILE"
        echo -e "${GREEN}✓ Database backed up to: $BACKUP_FILE${NC}"
    else
        echo -e "${YELLOW}⚠ Database container not running, skipping backup${NC}"
    fi
}

# Function to show logs
show_logs() {
    echo -e "${GREEN}Showing recent logs (Ctrl+C to exit)...${NC}"
    docker compose -f "$COMPOSE_FILE" logs -f --tail=50 backend
}

# Parse command line arguments
BACKUP=true
SHOW_LOGS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --no-backup)
            BACKUP=false
            shift
            ;;
        --logs)
            SHOW_LOGS=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --no-backup    Skip database backup"
            echo "  --logs         Show logs after deployment"
            echo "  --help         Show this help message"
            echo ""
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Main deployment process
echo "Starting deployment process..."
echo ""

# Backup database if enabled
if [ "$BACKUP" = true ]; then
    backup_database
    echo ""
fi

# Pull latest images
echo -e "${YELLOW}Pulling latest images from GHCR...${NC}"
docker compose -f "$COMPOSE_FILE" pull
echo -e "${GREEN}✓ Images pulled successfully${NC}"
echo ""

# Restart services
echo -e "${YELLOW}Restarting services...${NC}"
docker compose -f "$COMPOSE_FILE" up -d
echo -e "${GREEN}✓ Services restarted${NC}"
echo ""

# Wait for services to be ready
echo -e "${YELLOW}Waiting for services to start (10 seconds)...${NC}"
sleep 10

# Check service status
echo -e "${YELLOW}Checking service status...${NC}"
docker compose -f "$COMPOSE_FILE" ps
echo ""

# Verify backend is running
if docker compose -f "$COMPOSE_FILE" ps backend | grep -q "Up"; then
    echo -e "${GREEN}✓ Backend container is running${NC}"
else
    echo -e "${RED}✗ Backend container is not running!${NC}"
    echo "Check logs with: docker compose -f $COMPOSE_FILE logs backend"
    exit 1
fi

# Verify database is running
if docker compose -f "$COMPOSE_FILE" ps db | grep -q "Up"; then
    echo -e "${GREEN}✓ Database container is running${NC}"
else
    echo -e "${RED}✗ Database container is not running!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}=== Deployment completed successfully! ===${NC}"
echo ""
echo "Useful commands:"
echo "  View logs:           docker compose -f $COMPOSE_FILE logs -f backend"
echo "  Check status:        docker compose -f $COMPOSE_FILE ps"
echo "  Execute command:     docker exec backend python manage.py <command>"
echo "  Stop services:       docker compose -f $COMPOSE_FILE stop"
echo "  Restart services:    docker compose -f $COMPOSE_FILE restart"
echo ""

# Show logs if requested
if [ "$SHOW_LOGS" = true ]; then
    show_logs
fi
