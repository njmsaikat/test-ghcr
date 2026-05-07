#!/bin/bash
# Server Management Helper Script
# Common commands for managing your GHCR deployment

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

COMPOSE_FILE="docker-compose.prod.yml"

show_help() {
    echo -e "${GREEN}GHCR Deployment Management Helper${NC}"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo -e "  ${BLUE}logs${NC}           Show container logs (follow mode)"
    echo -e "  ${BLUE}logs-tail${NC}      Show last 100 lines of logs"
    echo -e "  ${BLUE}status${NC}         Show container status"
    echo -e "  ${BLUE}restart${NC}        Restart all services"
    echo -e "  ${BLUE}stop${NC}           Stop all services"
    echo -e "  ${BLUE}start${NC}          Start all services"
    echo -e "  ${BLUE}shell${NC}          Enter backend container shell"
    echo -e "  ${BLUE}dbshell${NC}        Enter PostgreSQL shell"
    echo -e "  ${BLUE}migrate${NC}        Run database migrations"
    echo -e "  ${BLUE}makemigrations${NC} Create new migrations"
    echo -e "  ${BLUE}collectstatic${NC}  Collect static files"
    echo -e "  ${BLUE}createsuperuser${NC} Create Django superuser"
    echo -e "  ${BLUE}backup${NC}         Backup database"
    echo -e "  ${BLUE}restore${NC} <file> Restore database from backup"
    echo -e "  ${BLUE}update${NC}         Pull latest images and restart"
    echo -e "  ${BLUE}clean${NC}          Clean up old Docker resources"
    echo -e "  ${BLUE}help${NC}           Show this help message"
    echo ""
}

case "$1" in
    logs)
        echo -e "${GREEN}Showing logs (Ctrl+C to exit)...${NC}"
        docker compose -f "$COMPOSE_FILE" logs -f backend
        ;;
    
    logs-tail)
        echo -e "${GREEN}Last 100 log lines:${NC}"
        docker compose -f "$COMPOSE_FILE" logs --tail=100 backend
        ;;
    
    status)
        echo -e "${GREEN}Container Status:${NC}"
        docker compose -f "$COMPOSE_FILE" ps
        echo ""
        echo -e "${GREEN}Resource Usage:${NC}"
        docker stats --no-stream
        ;;
    
    restart)
        echo -e "${YELLOW}Restarting services...${NC}"
        docker compose -f "$COMPOSE_FILE" restart
        echo -e "${GREEN}✓ Services restarted${NC}"
        ;;
    
    stop)
        echo -e "${YELLOW}Stopping services...${NC}"
        docker compose -f "$COMPOSE_FILE" stop
        echo -e "${GREEN}✓ Services stopped${NC}"
        ;;
    
    start)
        echo -e "${YELLOW}Starting services...${NC}"
        docker compose -f "$COMPOSE_FILE" up -d
        echo -e "${GREEN}✓ Services started${NC}"
        ;;
    
    shell)
        echo -e "${GREEN}Entering backend container...${NC}"
        docker exec -it backend bash
        ;;
    
    dbshell)
        echo -e "${GREEN}Entering PostgreSQL shell...${NC}"
        source .env.prod
        docker exec -it db psql -U ${DB_USER} -d ${DB_NAME}
        ;;
    
    migrate)
        echo -e "${YELLOW}Running migrations...${NC}"
        docker exec backend python manage.py migrate
        echo -e "${GREEN}✓ Migrations completed${NC}"
        ;;
    
    makemigrations)
        echo -e "${YELLOW}Creating migrations...${NC}"
        docker exec backend python manage.py makemigrations
        echo -e "${GREEN}✓ Migrations created${NC}"
        ;;
    
    collectstatic)
        echo -e "${YELLOW}Collecting static files...${NC}"
        docker exec backend python manage.py collectstatic --noinput
        echo -e "${GREEN}✓ Static files collected${NC}"
        ;;
    
    createsuperuser)
        echo -e "${GREEN}Creating superuser...${NC}"
        docker exec -it backend python manage.py createsuperuser
        ;;
    
    backup)
        BACKUP_FILE="backup_$(date +%Y%m%d_%H%M%S).sql"
        echo -e "${YELLOW}Backing up database to $BACKUP_FILE...${NC}"
        source .env.prod
        docker exec db pg_dump -U ${DB_USER} ${DB_NAME} > "$BACKUP_FILE"
        echo -e "${GREEN}✓ Database backed up to: $BACKUP_FILE${NC}"
        ;;
    
    restore)
        if [ -z "$2" ]; then
            echo -e "${YELLOW}Usage: $0 restore <backup-file>${NC}"
            echo ""
            echo "Available backups:"
            ls -lh backup_*.sql 2>/dev/null || echo "No backups found"
            exit 1
        fi
        
        if [ ! -f "$2" ]; then
            echo -e "${RED}Error: Backup file $2 not found${NC}"
            exit 1
        fi
        
        echo -e "${YELLOW}Restoring database from $2...${NC}"
        echo -e "${YELLOW}WARNING: This will overwrite current database!${NC}"
        read -p "Continue? (yes/no): " confirm
        
        if [ "$confirm" == "yes" ]; then
            source .env.prod
            docker exec -i db psql -U ${DB_USER} -d ${DB_NAME} < "$2"
            echo -e "${GREEN}✓ Database restored${NC}"
        else
            echo "Restore cancelled"
        fi
        ;;
    
    update)
        echo -e "${GREEN}Updating deployment...${NC}"
        ./scripts/deploy.sh --logs
        ;;
    
    clean)
        echo -e "${YELLOW}Cleaning up Docker resources...${NC}"
        docker image prune -f
        docker container prune -f
        echo -e "${GREEN}✓ Cleanup completed${NC}"
        echo ""
        echo "Disk usage:"
        docker system df
        ;;
    
    help|--help|-h)
        show_help
        ;;
    
    *)
        if [ -z "$1" ]; then
            show_help
        else
            echo -e "${RED}Unknown command: $1${NC}"
            echo ""
            show_help
            exit 1
        fi
        ;;
esac
