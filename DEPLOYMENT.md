# Simple GHCR Deployment Guide

Deploy Django app using GitHub Container Registry - **No source code needed on server!**

---

## 📋 Overview

**Workflow:**

1. **Local:** Push code to GitHub
2. **GitHub Actions:** Builds Docker image → Pushes to GHCR (automatic)
3. **Server:** Pull image and run (`docker compose up`)
4. **Migrations:** Run automatically on container startup

**Benefits:** ✅ No source code on server ✅ One command deployment ✅ Easy rollback ✅ Same environment everywhere

---

## Part 1: Local Setup

### 1. Create Environment File

```bash
cp .env.example .env
nano .env
```

For development, use defaults (DEBUG=1, simple passwords).

### 2. Test Locally

```bash
docker compose up --build
# Visit http://localhost:8000
```

---

## Part 2: Push to GHCR

### 3. Update docker-compose.yml

Edit `docker-compose.yml` line 6:

```yaml
image: ghcr.io/YOUR-GITHUB-USERNAME/test-ghcr-backend:latest
```

Replace `YOUR-GITHUB-USERNAME` with your actual username.

### 4. Push to GitHub

```bash
git add .
git commit -m "Setup deployment"
git push origin main
```

GitHub Actions builds and pushes image automatically (check **Actions** tab, takes 2-5 min).

### 5. Make Package Public

1. Go to `https://github.com/YOUR-USERNAME?tab=packages`
2. Click `test-ghcr-backend`
3. **Package Settings → Change visibility → Public**

---

## Part 3: Server Deployment

### 6. Install Docker on Server

```bash
ssh user@your-server-ip

# Install Docker
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
newgrp docker
```

### 7. Create Deployment Files on Server

```bash
mkdir -p ~/deploy && cd ~/deploy
```

**Create docker-compose.yml:**

```bash
nano docker-compose.yml
```

Paste (replace YOUR-USERNAME):

```yaml
services:
  backend:
    image: ghcr.io/YOUR-USERNAME/test-ghcr-backend:latest
    restart: always
    container_name: backend
    command: >
      sh -c "python manage.py wait_for_db &&
             python manage.py migrate &&
             python manage.py collectstatic --noinput &&
             gunicorn --bind 0.0.0.0:8000 --workers 3 myproject.wsgi:application"
    volumes:
      - static_volume:/app/backend/static
      - media_volume:/app/backend/media
    ports:
      - "8000:8000"
    depends_on:
      - db
    networks:
      - main
    env_file:
      - .env

  db:
    image: postgres:14-alpine
    restart: always
    container_name: db
    environment:
      POSTGRES_USER: ${DB_USER}
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      TZ: "Asia/Dhaka"
    volumes:
      - pgdata:/var/lib/postgresql/data
    networks:
      - main

networks:
  main:
    driver: bridge

volumes:
  pgdata:
  static_volume:
  media_volume:
```

**Create .env file:**

```bash
nano .env
```

Paste (customize SECRET_KEY and passwords):

```bash
# Django
SECRET_KEY=GENERATE-LONG-RANDOM-STRING-50-CHARS
DEBUG=0
ALLOWED_HOSTS=yourdomain.com www.yourdomain.com YOUR-SERVER-IP

# CORS
CORS_ORIGIN_WHITELIST=yourdomain.com
CORS_ALLOWED_ORIGINS=https://yourdomain.com

# Database
DB_ENGINE=django.db.backends.postgresql
DB_NAME=proddb
DB_USER=produser
DB_PASSWORD=STRONG-RANDOM-PASSWORD
DB_HOST=db
DB_PORT=5432
```

**Generate SECRET_KEY:**

```bash
python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'
```

### 8. Deploy!

```bash
# Pull image from GHCR
docker compose pull

# Start containers (migrations run automatically)
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f
```

### 9. Create Admin User

```bash
docker exec -it backend python manage.py createsuperuser
```

**Access:** `http://YOUR-SERVER-IP:8000/admin`

---

## 🔄 Updating Your App

**When you make code changes:**

**On local machine:**

```bash
git add .
git commit -m "New feature"
git push origin main
```

Wait 2-5 minutes for GitHub Actions to build.

**On server:**

```bash
cd ~/deploy
docker compose pull
docker compose up -d
docker compose logs -f backend
```

**Done!** New code deployed with migrations applied automatically.

---

## 📊 Handling Migrations

### Automatic (Default)

Migrations run on container start (already configured in docker-compose.yml).

**New migrations workflow:**

1. **Local:** Create models, generate migrations

   ```bash
   python manage.py makemigrations
   ```

2. **Commit and push:**

   ```bash
   git add .
   git commit -m "Add new model"
   git push
   ```

3. **Server:** Pull and restart

   ```bash
   docker compose pull
   docker compose up -d
   ```

   Migrations apply automatically! ✅

### Manual Control

```bash
# Check status
docker exec backend python manage.py showmigrations

# Run manually
docker exec backend python manage.py migrate

# Rollback to specific migration
docker exec backend python manage.py migrate myapp 0003_previous
```

### Migration Best Practices

1. ✅ **Always test locally first**
2. ✅ **Backup database before major migrations**
3. ✅ **Make migrations backward compatible when possible**
4. ❌ **Don't skip migrations in production**

---

## 🐛 Debugging & Troubleshooting

### View Logs

```bash
# All logs
docker compose logs -f

# Backend only (last 50 lines)
docker compose logs -f --tail=50 backend

# Database logs
docker compose logs db
```

### Access Container

```bash
# Backend shell
docker exec -it backend bash

# Inside container:
python manage.py shell
python manage.py check
exit
```

### Database Access

```bash
# Test connection
docker exec backend python manage.py wait_for_db

# PostgreSQL shell
docker exec -it db psql -U produser -d proddb

# Inside psql:
\dt                           # List tables
\d+ myapp_model              # Describe table
SELECT * FROM myapp_model;
\q                           # Exit
```

### Common Issues

**Container won't start:**

```bash
docker compose logs backend  # Check error messages
```

**Database connection failed:**

```bash
docker compose ps db         # Check DB is running
cat .env | grep DB_          # Verify credentials
```

**Static files not loading:**

```bash
docker exec backend python manage.py collectstatic --noinput
```

**Port already in use:**

```bash
sudo lsof -i :8000           # Check what's using port
# Change port in docker-compose.yml: "8080:8000"
```

---

## 🔙 Rollback

### Use Previous Image

```bash
# Check available tags at:
# https://github.com/YOUR-USERNAME/test-ghcr/pkgs/container/test-ghcr-backend

# Pull specific version (use commit SHA tag)
docker pull ghcr.io/YOUR-USERNAME/test-ghcr-backend:main-abc1234

# Update docker-compose.yml image line, then:
docker compose up -d
```

---

## 💾 Backup & Restore

### Backup Database

```bash
# Manual backup
docker exec db pg_dump -U produser proddb > backup_$(date +%Y%m%d).sql

# Automated daily backup (add to crontab)
crontab -e
# Add: 0 2 * * * docker exec db pg_dump -U produser proddb > ~/backups/backup_$(date +\%Y\%m\%d).sql
```

### Restore Database

```bash
docker compose stop backend
cat backup_20260510.sql | docker exec -i db psql -U produser -d proddb
docker compose start backend
```

---

## ⚖️ Pros & Cons

### ✅ Pros

1. **No Source Code on Server** - More secure, can't accidentally edit
2. **Consistent Environments** - Same image everywhere
3. **Simple Deployment** - Single command: `docker compose pull && up -d`
4. **Easy Rollback** - Use previous image tags
5. **Automatic Migrations** - No manual steps

### ❌ Cons

1. **Slower Development Iteration** - Need build → push → pull cycle (2-5 min wait)
   - _Workaround:_ Test locally first, only push when ready

2. **Harder Debugging** - Can't edit files directly on server
   - _Workaround:_ Check logs: `docker compose logs -f`, use `docker exec -it backend bash`

3. **Migration Rollback Complex** - Auto-migrations harder to reverse
   - _Workaround:_ Backup DB before deployment, test locally first

4. **Build Time** - Every change requires full rebuild
   - _Workaround:_ Use Docker layer caching (already configured)

5. **Storage Usage** - Multiple image versions consume disk space
   - _Workaround:_ Clean old images: `docker image prune -a`

6. **Internet Dependency** - Server needs internet to pull images
   - _Workaround:_ Keep local copy, use `docker save/load` for offline

---

## 🔧 Alternative: Quick Debugging on Server

If you need to debug with live code editing on server:

**Temporary debug mode:**

```bash
# Clone code temporarily on server
git clone https://github.com/YOUR-USERNAME/test-ghcr.git debug-code

# Modify docker-compose.yml temporarily:
volumes:
  - ./debug-code/backend:/app/backend  # Mount local code
command: python manage.py runserver 0.0.0.0:8000  # Dev server

docker compose up
```

Edit files with `nano debug-code/backend/...`, changes apply immediately.

**Note:** This is for debugging only. Remove for production!

---

## 📚 Quick Reference

```bash
# Deploy/Update
docker compose pull && docker compose up -d

# View logs
docker compose logs -f

# Restart
docker compose restart backend

# Stop all
docker compose down

# Check status
docker compose ps

# Django commands
docker exec backend python manage.py <command>

# Create superuser
docker exec -it backend python manage.py createsuperuser

# Backup database
docker exec db pg_dump -U produser proddb > backup.sql

# Clean up
docker system prune -a

# Check disk usage
docker system df
```

---

## 🎯 Summary

**This approach is best for:**

- Production deployments
- Multiple server scaling
- Teams wanting consistency
- CI/CD automation

**Choose traditional approach (git clone on server) if:**

- You need frequent live debugging on server
- Team unfamiliar with Docker
- Very rapid iteration needed

**Best practice:** Use GHCR for production, Docker locally for development.

---

**Need help?** Check logs first: `docker compose logs -f backend`

**Happy deploying! 🚀**
