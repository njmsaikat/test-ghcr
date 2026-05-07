# GHCR Deployment Guide

Complete guide for deploying this Django project using GitHub Container Registry (GHCR) without pulling source code on the server.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Local Setup](#local-setup)
3. [GitHub Setup](#github-setup)
4. [Server Setup](#server-setup)
5. [Deployment Process](#deployment-process)
6. [Handling Migrations](#handling-migrations)
7. [Debugging & Troubleshooting](#debugging--troubleshooting)
8. [Rollback Procedure](#rollback-procedure)

---

## Prerequisites

### Local Machine

- Docker and Docker Compose installed
- Git configured
- GitHub account with repository access

### Server

- Ubuntu/Debian Linux server (or similar)
- Docker and Docker Compose installed
- Domain name pointed to server (optional but recommended)
- Ports 80, 443 (for web traffic) and optionally 8000 (for direct access) open

---

## Local Setup

### 1. Test Local Build

```bash
# Build the backend image locally
docker build -f docker/backend/Dockerfile -t test-ghcr-backend:local .

# Test with development docker-compose
docker compose up
```

Visit http://localhost:8000 to verify it works.

### 2. Configure Your Environment

Update `.env/dev.env` for local development if needed. Don't commit sensitive production values!

---

## GitHub Setup

### 1. Enable GitHub Packages

Your repository needs to be on GitHub. The workflow in `.github/workflows/deploy-image.yml` will automatically:

- Build Docker images on push to main/master
- Push images to GHCR (GitHub Container Registry)
- Tag images appropriately

### 2. Make Image Public (Recommended for Easy Access)

After first push:

1. Go to your GitHub profile → Packages
2. Find `test-ghcr-backend` package
3. Click Package Settings → Change visibility → Public
4. This allows pulling without authentication (simpler for deployment)

### 3. Create Personal Access Token (if using private images)

1. GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token with these scopes:
   - `read:packages` (for pulling images)
   - `write:packages` (for pushing images)
3. Save this token securely - you'll need it on the server

---

## Server Setup

### 1. Install Docker & Docker Compose

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo apt install docker-compose-plugin

# Add your user to docker group (to run without sudo)
sudo usermod -aG docker $USER
newgrp docker

# Verify installation
docker --version
docker compose version
```

### 2. Create Deployment Directory

```bash
# Create deployment directory
mkdir -p ~/deployments/test-ghcr
cd ~/deployments/test-ghcr
```

### 3. Copy Production Files to Server

Copy only these files to your server (NOT the entire codebase):

```bash
# On your local machine, from project root
scp docker-compose.prod.yml user@your-server:~/deployments/test-ghcr/
scp .env.prod.example user@your-server:~/deployments/test-ghcr/.env.prod
```

Or create them directly on the server (recommended):

```bash
# On server
cd ~/deployments/test-ghcr

# Download docker-compose.prod.yml from your repo
wget https://raw.githubusercontent.com/YOUR-USERNAME/test-ghcr/main/docker-compose.prod.yml

# Or create it manually (copy content from the file)
nano docker-compose.prod.yml
```

### 4. Configure Production Environment

```bash
# On server
cd ~/deployments/test-ghcr
nano .env.prod
```

Add your production configuration:

```bash
# Django Settings
SECRET_KEY=your-very-long-random-secret-key-at-least-50-characters
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com,123.45.67.89
DEBUG=False

# CORS Settings
CORS_ORIGIN_WHITELIST=yourdomain.com,www.yourdomain.com
CORS_ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com

# Database Configuration
PRODUCTION=True
DB_ENGINE=django.db.backends.postgresql
DB_NAME=mydb_prod
DB_USER=produser
DB_PASSWORD=your-strong-database-password-here
DB_HOST=db
DB_PORT=5432

# GitHub Settings
GITHUB_USERNAME=your-github-username
```

**Generate SECRET_KEY:**

```bash
python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'
```

### 5. Login to GHCR (if private image)

```bash
# If your image is private, login with PAT
echo YOUR_GITHUB_TOKEN | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin
```

If image is public, you can skip this step.

---

## Deployment Process

### Initial Deployment

```bash
# On server
cd ~/deployments/test-ghcr

# Pull latest images
docker compose -f docker-compose.prod.yml pull

# Start services (migrations run automatically)
docker compose -f docker-compose.prod.yml up -d

# Check logs
docker compose -f docker-compose.prod.yml logs -f

# Verify containers are running
docker compose -f docker-compose.prod.yml ps
```

### Create Django Superuser

```bash
docker exec -it backend python manage.py createsuperuser
```

### Update Deployment (After Code Changes)

```bash
# 1. Push code to GitHub (images build automatically via GitHub Actions)

# 2. On server, pull new images
docker compose -f docker-compose.prod.yml pull

# 3. Recreate containers
docker compose -f docker-compose.prod.yml up -d

# 4. Monitor logs
docker compose -f docker-compose.prod.yml logs -f backend
```

---

## Handling Migrations

### Automatic (Recommended - Already Configured)

Migrations run automatically when container starts (configured in docker-compose.prod.yml command).

### Manual Migration Run

```bash
# Check migration status
docker exec backend python manage.py showmigrations

# Run migrations manually
docker exec backend python manage.py migrate

# Create new migrations (if needed during development)
docker exec backend python manage.py makemigrations

# Check for migration issues
docker exec backend python manage.py migrate --plan
```

### Zero-Downtime Migration Strategy

For production with users:

```bash
# 1. Backup database first!
docker exec db pg_dump -U produser mydb_prod > backup_$(date +%Y%m%d_%H%M%S).sql

# 2. Pull new image
docker compose -f docker-compose.prod.yml pull backend

# 3. Run migrations without restarting app
docker run --rm \
  --network test-ghcr_main \
  --env-file .env.prod \
  ghcr.io/YOUR-USERNAME/test-ghcr-backend:latest \
  python manage.py migrate

# 4. Now restart with new code
docker compose -f docker-compose.prod.yml up -d
```

---

## Debugging & Troubleshooting

### View Logs

```bash
# All services
docker compose -f docker-compose.prod.yml logs -f

# Backend only
docker compose -f docker-compose.prod.yml logs -f backend

# Last 100 lines
docker compose -f docker-compose.prod.yml logs --tail=100 backend

# Database logs
docker compose -f docker-compose.prod.yml logs db
```

### Access Container Shell

```bash
# Enter backend container
docker exec -it backend bash

# Once inside, you can run Django commands
python manage.py shell
python manage.py check
python manage.py showmigrations
```

### Database Debugging

```bash
# Test database connection
docker exec backend python manage.py wait_for_db

# Access PostgreSQL shell
docker exec -it db psql -U produser -d mydb_prod

# Inside psql:
\dt          # List tables
\d+ tablename # Describe table
\q           # Quit
```

### Check Container Status

```bash
# List containers
docker compose -f docker-compose.prod.yml ps

# Container resource usage
docker stats

# Inspect container
docker inspect backend

# Check networks
docker network ls
docker network inspect test-ghcr_main
```

### Common Issues

#### 1. Container Won't Start

```bash
# Check logs
docker compose -f docker-compose.prod.yml logs backend

# Common causes:
# - Database not ready: wait_for_db should handle this
# - Migration errors: check migration logs
# - Environment variable issues: verify .env.prod
```

#### 2. Database Connection Errors

```bash
# Verify database is running
docker compose -f docker-compose.prod.yml ps db

# Test connection
docker exec backend python manage.py wait_for_db

# Check DB credentials in .env.prod
cat .env.prod | grep DB_
```

#### 3. Static Files Not Loading

```bash
# Collect static files
docker exec backend python manage.py collectstatic --noinput

# Check static volume
docker volume inspect test-ghcr_static_volume

# Verify STATIC_ROOT in Django settings
docker exec backend python manage.py diffsettings | grep STATIC
```

#### 4. Permission Issues

```bash
# Check file permissions in container
docker exec backend ls -la /app/backend

# Check volume permissions
docker exec backend ls -la /app/backend/media
```

#### 5. Image Pull Issues

```bash
# Verify you're logged in (if private repo)
docker login ghcr.io

# Check image exists
docker manifest inspect ghcr.io/YOUR-USERNAME/test-ghcr-backend:latest

# Pull manually to see errors
docker pull ghcr.io/YOUR-USERNAME/test-ghcr-backend:latest
```

### Health Checks

```bash
# Check if backend is responding
curl http://localhost:8000

# Check database
docker exec db pg_isready -U produser

# Check disk space
df -h

# Check Docker disk usage
docker system df
```

---

## Rollback Procedure

### Rollback to Previous Version

```bash
# 1. Find previous image tag
# Check GitHub packages or use git SHA

# 2. Update image in docker-compose.prod.yml or use override
docker compose -f docker-compose.prod.yml stop backend

docker run -d \
  --name backend \
  --network test-ghcr_main \
  --env-file .env.prod \
  -p 8000:8000 \
  ghcr.io/YOUR-USERNAME/test-ghcr-backend:previous-sha

# OR better: tag the working version
docker tag ghcr.io/YOUR-USERNAME/test-ghcr-backend:working-sha \
           ghcr.io/YOUR-USERNAME/test-ghcr-backend:latest

# 3. Verify rollback worked
docker compose -f docker-compose.prod.yml logs -f backend
```

### Database Rollback

```bash
# List backups
ls -lh backup_*.sql

# Restore from backup
docker exec -i db psql -U produser -d mydb_prod < backup_20260507_120000.sql

# Or reverse specific migration
docker exec backend python manage.py migrate app_name migration_name
```

---

## Monitoring & Maintenance

### Regular Maintenance Tasks

```bash
# Clean up old Docker images
docker image prune -a

# Clean up stopped containers
docker container prune

# Clean up unused volumes (careful!)
docker volume prune

# View disk usage
docker system df
```

### Backup Strategy

```bash
# Create backup script
cat > backup.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
docker exec db pg_dump -U produser mydb_prod | gzip > backup_${DATE}.sql.gz
# Keep only last 7 days
find . -name "backup_*.sql.gz" -mtime +7 -delete
EOF

chmod +x backup.sh

# Add to crontab (daily at 2 AM)
crontab -e
# Add: 0 2 * * * /home/user/deployments/test-ghcr/backup.sh
```

### Update Process

```bash
# Complete update script
cat > update.sh << 'EOF'
#!/bin/bash
set -e

cd ~/deployments/test-ghcr

echo "Pulling latest images..."
docker compose -f docker-compose.prod.yml pull

echo "Backing up database..."
docker exec db pg_dump -U produser mydb_prod > backup_$(date +%Y%m%d_%H%M%S).sql

echo "Restarting services..."
docker compose -f docker-compose.prod.yml up -d

echo "Waiting for services to start..."
sleep 10

echo "Checking status..."
docker compose -f docker-compose.prod.yml ps

echo "Showing recent logs..."
docker compose -f docker-compose.prod.yml logs --tail=50 backend
EOF

chmod +x update.sh
```

---

## Security Best Practices

1. **Never commit .env.prod to git** - Already configured in .gitignore
2. **Use strong passwords** for database
3. **Keep SECRET_KEY secret** - Generate unique for production
4. **Don't expose database port** - Already configured (no ports in db service)
5. **Use HTTPS** - Set up nginx/caddy reverse proxy with SSL
6. **Regular updates** - Update base images and dependencies
7. **Monitor logs** - Check for suspicious activity
8. **Backup regularly** - Automate database backups
9. **Limit DEBUG=False** - Never run DEBUG=True in production
10. **Use specific image tags** - Instead of :latest for critical deployments

---

## Quick Reference Commands

```bash
# Start services
docker compose -f docker-compose.prod.yml up -d

# Stop services
docker compose -f docker-compose.prod.yml stop

# Restart services
docker compose -f docker-compose.prod.yml restart

# View logs
docker compose -f docker-compose.prod.yml logs -f

# Execute command
docker exec backend python manage.py <command>

# Update deployment
docker compose -f docker-compose.prod.yml pull && docker compose -f docker-compose.prod.yml up -d

# Backup database
docker exec db pg_dump -U produser mydb_prod > backup.sql

# Restore database
docker exec -i db psql -U produser -d mydb_prod < backup.sql
```

---

## Support & Resources

- GitHub Actions logs: Check your repository Actions tab
- GHCR packages: https://github.com/YOUR-USERNAME?tab=packages
- Django docs: https://docs.djangoproject.com/
- Docker docs: https://docs.docker.com/
- Docker Compose: https://docs.docker.com/compose/

---

**Remember:** With GHCR deployment, you never need source code on your server. Only Docker images, docker-compose.prod.yml, and .env.prod are needed!
