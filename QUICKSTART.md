# GHCR Quick Start Guide

Fast setup guide for deploying to production server.

## On Your Local Machine

### 1. Push to GitHub

```bash
git add .
git commit -m "Setup GHCR deployment"
git push origin main
```

GitHub Actions will automatically build and push the image to GHCR.

### 2. Make Package Public (Recommended)

1. Go to https://github.com/YOUR-USERNAME?tab=packages
2. Click on `test-ghcr-backend`
3. Package Settings → Change visibility → Public

---

## On Your Server

### 1. Install Docker

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker
```

### 2. Create Deployment Directory

```bash
mkdir -p ~/deployments/test-ghcr
cd ~/deployments/test-ghcr
```

### 3. Create docker-compose.prod.yml

```bash
nano docker-compose.prod.yml
```

Paste the content from your repository's `docker-compose.prod.yml` and update:

- Change `${GITHUB_USERNAME}` to your actual GitHub username

### 4. Create .env.prod

```bash
nano .env.prod
```

Add:

```bash
SECRET_KEY=<generate-long-random-key>
ALLOWED_HOSTS=yourdomain.com,your-server-ip
DEBUG=False
CORS_ORIGIN_WHITELIST=yourdomain.com
CORS_ALLOWED_ORIGINS=https://yourdomain.com

PRODUCTION=True
DB_ENGINE=django.db.backends.postgresql
DB_NAME=mydb_prod
DB_USER=produser
DB_PASSWORD=<strong-password>
DB_HOST=db
DB_PORT=5432

GITHUB_USERNAME=your-github-username
```

Generate SECRET_KEY:

```bash
python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'
```

### 5. Deploy

```bash
# Pull and start
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d

# Watch logs
docker compose -f docker-compose.prod.yml logs -f
```

### 6. Create Superuser

```bash
docker exec -it backend python manage.py createsuperuser
```

### 7. Access Your App

```
http://your-server-ip:8000
```

---

## Updates

```bash
# Pull latest
docker compose -f docker-compose.prod.yml pull

# Restart
docker compose -f docker-compose.prod.yml up -d

# Check logs
docker compose -f docker-compose.prod.yml logs -f backend
```

---

## Debugging

```bash
# View logs
docker compose -f docker-compose.prod.yml logs -f backend

# Enter container
docker exec -it backend bash

# Check database
docker exec -it db psql -U produser -d mydb_prod

# Run migrations manually
docker exec backend python manage.py migrate
```

---

For detailed documentation, see [DEPLOYMENT.md](DEPLOYMENT.md)
