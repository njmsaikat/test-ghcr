# SIMPLIFIED DEPLOYMENT PROCESS - COMPLETE GUIDE

This document explains the complete simplified deployment process for your Django + PostgreSQL project using GitHub Container Registry (GHCR).

---

## 🎯 What Changed?

### Before (Complex)

- Multiple docker-compose files (dev and prod)
- Multiple .env files in different locations
- Confusing documentation split across files
- Extra files not needed
- Unclear migration process

### After (Simple)

- **Single docker-compose.yml** - Works for both dev and prod (with comments)
- **Single .env file** - One file for all configuration
- **Clear DEPLOYMENT.md** - Step-by-step guide with explanations
- **Clean project** - Removed unnecessary files
- **Clear migration strategy** - Automatic with fallback options

---

## 📁 Project Structure (Simplified)

```
test-ghcr/
├── backend/                     # Django app
│   ├── myproject/              # Django settings
│   ├── myapp/                  # Your app
│   ├── config/                 # Config app
│   ├── manage.py
│   └── requirements.txt
├── docker/
│   └── backend/
│       └── Dockerfile          # Backend image definition
├── .github/
│   └── workflows/
│       └── deploy-image.yml    # Auto-build on push to GitHub
├── .env                        # Your config (create from .env.example)
├── .env.example                # Template - COMMIT THIS
├── docker-compose.yml          # Single compose file
├── README.md                   # Quick start guide
└── DEPLOYMENT.md               # Complete deployment guide
```

**Removed:**

- ❌ docker-compose.prod.yml (merged into docker-compose.yml)
- ❌ QUICKSTART.md (info moved to README and DEPLOYMENT)
- ❌ SETUP_SUMMARY.md (not needed)
- ❌ Dockerfile (root level - was just a placeholder)
- ❌ frontend/ (not used)
- ❌ scripts/ (not needed for Docker deployment)
- ❌ .env.prod.example (replaced by .env.example)
- ❌ .env/prod.env.template (replaced by .env.example)

**Kept:**

- ✅ .env/dev.env (for reference, but you can use .env instead)
- ✅ docker/backend/Dockerfile (the actual build file)

---

## 🚀 Complete Deployment Process

### Step 1: Local Development

1. **Setup:**

   ```bash
   cp .env.example .env
   nano .env  # Edit if needed (defaults are fine)
   ```

2. **Start:**

   ```bash
   docker compose up --build
   ```

3. **Access:**
   - App: http://localhost:8000
   - Admin: http://localhost:8000/admin

4. **Create admin:**
   ```bash
   docker exec -it backend python manage.py createsuperuser
   ```

### Step 2: Push to GitHub Container Registry (GHCR)

1. **Update docker-compose.yml** (line 6):

   ```yaml
   image: ghcr.io/YOUR-ACTUAL-USERNAME/test-ghcr-backend:latest
   ```

2. **Push to GitHub:**

   ```bash
   git add .
   git commit -m "Setup GHCR deployment"
   git push origin main
   ```

3. **Wait for build:**
   - Go to repo → **Actions** tab
   - Wait 2-5 minutes for build to complete
   - Image is pushed to GHCR automatically

4. **Make package public:**
   - Visit `https://github.com/YOUR-USERNAME?tab=packages`
   - Click `test-ghcr-backend`
   - Package Settings → Change visibility → **Public**
   - This allows pulling without authentication

### Step 3: Server Deployment

1. **Install Docker on server:**

   ```bash
   ssh user@your-server

   # Install Docker
   curl -fsSL https://get.docker.com | sudo sh
   sudo usermod -aG docker $USER
   newgrp docker
   ```

2. **Create deployment directory:**

   ```bash
   mkdir -p ~/deploy
   cd ~/deploy
   ```

3. **Create docker-compose.yml on server:**

   ```bash
   nano docker-compose.yml
   ```

   Copy the production version from DEPLOYMENT.md or copy your local file and:
   - Uncomment the `image:` line
   - Comment out the `build:` section
   - Update command to use `gunicorn`
   - Update volumes to only mount persistent data

4. **Create .env on server:**

   ```bash
   nano .env
   ```

   Use production values:
   - `DEBUG=0`
   - Strong `SECRET_KEY`
   - Strong `DB_PASSWORD`
   - Your domain/IP in `ALLOWED_HOSTS`

5. **Deploy:**

   ```bash
   # Pull image from GHCR
   docker compose pull

   # Start containers (migrations run automatically!)
   docker compose up -d

   # Check logs
   docker compose logs -f
   ```

6. **Create admin user:**

   ```bash
   docker exec -it backend python manage.py createsuperuser
   ```

7. **Access:**
   - App: http://YOUR-SERVER-IP:8000
   - Admin: http://YOUR-SERVER-IP:8000/admin

---

## 🔄 How Updates Work

### Making Code Changes

**On your local machine:**

1. Make your changes to Django code
2. Test locally:

   ```bash
   docker compose up --build
   ```

3. If using new models, create migrations:

   ```bash
   docker exec backend python manage.py makemigrations
   ```

4. Test migrations locally:

   ```bash
   docker exec backend python manage.py migrate
   ```

5. Commit and push:
   ```bash
   git add .
   git commit -m "Add new feature"
   git push origin main
   ```

**Automatically (GitHub Actions):**

- Detects push to main branch
- Builds new Docker image with your code
- Pushes to GHCR with tags:
  - `latest` (most recent)
  - `main-COMMIT_SHA` (specific version)

**On your server:**

1. Pull new image:

   ```bash
   cd ~/deploy
   docker compose pull
   ```

2. Restart with new image:

   ```bash
   docker compose up -d
   ```

3. Migrations run automatically on startup!

4. Check logs:
   ```bash
   docker compose logs -f backend
   ```

**That's it!** Your new code is live with migrations applied.

---

## 📊 Migration Handling Explained

### How Migrations Work in This Setup

**The Command in docker-compose.yml:**

```yaml
command: >
  sh -c "python manage.py wait_for_db &&
         python manage.py migrate &&          # ← Runs migrations automatically
         python manage.py collectstatic --noinput &&
         gunicorn --bind 0.0.0.0:8000 --workers 3 myproject.wsgi:application"
```

Every time the container starts, it:

1. Waits for database to be ready
2. **Runs migrations** (applies any pending migrations)
3. Collects static files
4. Starts the application server

### Workflow for New Migrations

**Scenario: You add a new model to your Django app**

1. **Local development:**

   ```bash
   # Create model in models.py

   # Generate migration file
   docker exec backend python manage.py makemigrations

   # Apply locally to test
   docker exec backend python manage.py migrate

   # Test your app to ensure it works
   ```

2. **Commit migration files:**

   ```bash
   git add backend/myapp/migrations/
   git commit -m "Add User profile model"
   git push origin main
   ```

3. **GitHub Actions:**
   - Builds new image
   - Migration files are included in the image
   - Pushes to GHCR

4. **On server:**

   ```bash
   docker compose pull    # Get new image with migrations
   docker compose up -d   # Restart container
   ```

   On restart:
   - Container runs `python manage.py migrate`
   - Detects new migration files
   - Applies them to production database
   - Starts application

**Result:** Migrations applied automatically! ✅

### Manual Migration Control

If you want more control:

**Check migration status:**

```bash
docker exec backend python manage.py showmigrations
```

**Run migrations manually:**

```bash
docker exec backend python manage.py migrate
```

**Rollback to specific migration:**

```bash
docker exec backend python manage.py migrate myapp 0003_previous_migration
```

**Fake a migration (mark as applied without running):**

```bash
docker exec backend python manage.py migrate myapp 0004 --fake
```

### Migration Best Practices

✅ **DO:**

- Test migrations locally first
- Backup database before major migrations
- Make migrations backward compatible
- Review migration SQL: `python manage.py sqlmigrate myapp 0001`
- Use data migrations for complex transformations

❌ **DON'T:**

- Skip migrations in production
- Delete migration files after applying
- Edit applied migrations
- Forget to commit migration files to git

### Handling Migration Failures

**If migration fails on server:**

1. **Check logs:**

   ```bash
   docker compose logs backend
   ```

2. **Access container:**

   ```bash
   docker exec -it backend bash
   python manage.py migrate --plan  # See what would run
   python manage.py migrate --fake-initial  # If tables exist
   ```

3. **Rollback if needed:**

   ```bash
   docker exec backend python manage.py migrate myapp 0003_previous
   ```

4. **Fix and redeploy:**
   - Fix migration locally
   - Test thoroughly
   - Push to GitHub
   - Pull and restart on server

---

## 🐛 Debugging Procedures

### Level 1: Check Logs

**First step for any issue:**

```bash
docker compose logs -f
```

**Backend only:**

```bash
docker compose logs -f backend
```

**Last 50 lines:**

```bash
docker compose logs --tail=50 backend
```

**Database logs:**

```bash
docker compose logs db
```

### Level 2: Check Container Status

```bash
# Are containers running?
docker compose ps

# Container details
docker inspect backend

# Resource usage
docker stats

# Disk usage
docker system df
```

### Level 3: Access Container

**Enter backend container:**

```bash
docker exec -it backend bash
```

**Inside container, you can:**

```bash
# Django shell
python manage.py shell

# Check Django configuration
python manage.py check

# Check migrations
python manage.py showmigrations

# Run Django tests
python manage.py test

# Check installed packages
pip list

# View files
ls -la /app/backend
cat /app/backend/myproject/settings.py

# Exit container
exit
```

### Level 4: Database Debugging

**Test database connection:**

```bash
docker exec backend python manage.py wait_for_db
```

**Access PostgreSQL:**

```bash
docker exec -it db psql -U produser -d proddb
```

**Inside PostgreSQL:**

```sql
-- List databases
\l

-- Connect to database
\c proddb

-- List tables
\dt

-- Describe table
\d+ myapp_model

-- Query data
SELECT * FROM myapp_model LIMIT 10;

-- Check table size
SELECT pg_size_pretty(pg_total_relation_size('myapp_model'));

-- Exit
\q
```

### Level 5: Network Debugging

**Check Docker networks:**

```bash
docker network ls
docker network inspect deploy_main
```

**Test connectivity:**

```bash
# From backend to database
docker exec backend ping db

# Check if backend can reach database port
docker exec backend nc -zv db 5432
```

### Common Issues & Solutions

#### Issue: Container won't start

**Debug:**

```bash
docker compose logs backend
docker compose ps
```

**Common causes:**

- Database not ready → `wait_for_db` should handle this
- Migration error → Check migration logs
- Syntax error in code → Check logs for Python traceback
- Port already in use → Change port in docker-compose.yml

#### Issue: Database connection refused

**Debug:**

```bash
# Check DB is running
docker compose ps db

# Check DB credentials in .env
cat .env | grep DB_

# Test connection
docker exec backend python manage.py wait_for_db
```

**Solution:**

- Ensure DB_HOST=db (not localhost)
- Check DB_USER, DB_PASSWORD match
- Verify db container is running

#### Issue: Changes not reflected

**Possible causes:**

1. **Forgot to rebuild image:**

   ```bash
   git push origin main  # Wait for GitHub Actions
   docker compose pull   # On server
   docker compose up -d
   ```

2. **Cached layer:**

   ```bash
   docker compose build --no-cache
   docker compose up -d
   ```

3. **Wrong container:**
   ```bash
   docker compose ps  # Check which image is running
   ```

#### Issue: Static files not loading

**Solution:**

```bash
docker exec backend python manage.py collectstatic --noinput
docker compose restart backend
```

#### Issue: Migration already applied error

**Solution:**

```bash
# Mark migration as fake-applied
docker exec backend python manage.py migrate --fake myapp 0004
```

---

## ⚖️ Pros & Cons Analysis

### ✅ Advantages of This GHCR Approach

#### 1. No Source Code on Server

**Pro:** More secure

- Can't accidentally view/edit production code
- No sensitive files on server (beyond .env)
- Reduced attack surface
- Server compromise doesn't expose source code

**Con:** Can't quick-fix on server

- Must push → build → pull → deploy
- 2-5 minute delay for changes
- Can't use `nano` to fix typo

**Workaround:** Test thoroughly locally before deploying

#### 2. Consistent Environments

**Pro:** "Works on my machine" = works everywhere

- Same Docker image in dev, staging, prod
- No "pip install" version mismatches
- Reproducible builds

**Con:** Local environment differences matter less

- Might miss OS-specific issues
- Must test in Docker locally

**Workaround:** Always test with `docker compose up` locally

#### 3. Simple Deployment

**Pro:** One command

- `docker compose pull && docker compose up -d`
- No git clone, pip install, collectstatic manually
- Fast rollback with image tags

**Con:** Dependency on internet

- Can't deploy if GHCR is down
- Requires stable connection to pull images

**Workaround:** Keep backup images locally with `docker save/load`

#### 4. Automatic Migrations

**Pro:** No manual migration step

- Migrations run on container start
- Less human error
- Consistent process

**Con:** Less control over migration timing

- Can't easily skip a problematic migration
- Harder to do zero-downtime migrations
- Rollback requires manual intervention

**Workaround:**

- Test migrations locally first
- Backup database before deployment
- Use `docker exec` for manual control if needed

#### 5. Easy Scaling

**Pro:** Same image on multiple servers

- Horizontal scaling simplified
- Load balancer ready
- Kubernetes-ready architecture

**Con:** All servers must have internet access

- Initial setup on each server required

#### 6. CI/CD Ready

**Pro:** Automated pipeline

- Push to GitHub → Auto-build → Ready to deploy
- Can add automated tests to workflow
- Can deploy to multiple environments

**Con:** Build time adds delay

- 2-5 minutes per build
- Failed builds block deployment

---

### ❌ Disadvantages & Workarounds

#### 1. Slower Iteration in Production

**Problem:**

- Change code → push → wait for build → pull → restart
- 2-5 minute delay minimum
- Can't quickly test on production

**Workaround:**

- **Test locally first** with `docker compose up`
- Use staging environment for testing
- For urgent debugging, temporarily mount code:
  ```bash
  # Temporary debug mode on server
  git clone https://github.com/YOUR-USERNAME/test-ghcr.git debug
  # Edit docker-compose.yml to mount ./debug/backend
  # Make changes, test, then revert to image-based deployment
  ```

**When it's acceptable:**

- Production should be stable anyway
- Changes should be tested in dev/staging first
- Slower deployment encourages better testing

#### 2. Harder Debugging

**Problem:**

- Can't see source code on server
- Can't edit files directly
- Must use logs and container exec

**Workaround:**

```bash
# View logs
docker compose logs -f backend

# Access container
docker exec -it backend bash

# Django shell for debugging
docker exec -it backend python manage.py shell

# Enable verbose logging in production:
# In settings.py, configure logging:
LOGGING = {
    'version': 1,
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
        },
    },
    'root': {
        'handlers': ['console'],
        'level': 'INFO',
    },
}
```

**Best practice:**

- Use structured logging
- Send logs to external service (ELK, CloudWatch, etc.)
- Add health check endpoints for monitoring

#### 3. Complex Migration Rollbacks

**Problem:**

- Migrations run automatically on start
- Can't easily skip or fake migrations
- Reversing migrations requires manual commands

**Workaround:**

```bash
# Before major migrations, backup:
docker exec db pg_dump -U produser proddb > backup.sql

# If migration fails, rollback:
docker exec backend python manage.py migrate myapp 0003_previous

# Or restore database:
docker compose stop backend
cat backup.sql | docker exec -i db psql -U produser -d proddb
docker compose start backend
```

**Best practice:**

- Test migrations locally thoroughly
- Make migrations backward compatible when possible
- Use Django's `migrations.RunPython` for complex data migrations
- Consider blue-green deployment for zero-downtime

#### 4. Build Time Overhead

**Problem:**

- Every change requires full image rebuild
- GitHub Actions takes 2-5 minutes
- Larger images take longer to pull

**Workaround:**

- **Layer caching** (already configured in workflow)
- Keep image size small:

  ```dockerfile
  # Use slim base images
  FROM python:3.8-slim

  # Clean up after installs
  RUN apt-get update && apt-get install -y pkg \
      && rm -rf /var/lib/apt/lists/*
  ```

- Use multi-stage builds (for further optimization)

**Already optimized:**

- GitHub Actions caches layers
- Docker BuildX cache configured

#### 5. Storage Usage

**Problem:**

- Multiple image versions consume disk space
- Old images accumulate
- Volumes persist data

**Workaround:**

```bash
# Clean old images (keeps used ones)
docker image prune -a

# Clean stopped containers
docker container prune

# Clean unused volumes (CAREFUL!)
docker volume prune

# Check disk usage
docker system df

# Clean everything unused
docker system prune -a --volumes
```

**Best practice:**

- Regular cleanup scheduled via cron
- Monitor disk space: `df -h`
- Set up alerts for low disk space

#### 6. Internet Dependency

**Problem:**

- Server needs internet to pull images
- GitHub/GHCR downtime blocks deployment
- Can't deploy in air-gapped environments

**Workaround:**

```bash
# Save image locally
docker save ghcr.io/YOUR-USERNAME/test-ghcr-backend:latest > backend.tar

# Transfer to server (USB, SCP, etc.)
scp backend.tar user@server:/tmp/

# Load on server
docker load < /tmp/backend.tar

# Now docker compose up will use local image
```

**Or:**

- Set up private registry mirror
- Use Docker registry cache
- Keep multiple tagged versions locally

---

## 🔄 Alternative Deployment Approaches

### Option 1: Traditional Deployment (Source Code on Server)

**Setup:**

```bash
# On server
git clone https://github.com/YOUR-USERNAME/test-ghcr.git
cd test-ghcr/backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py collectstatic
gunicorn myproject.wsgi:application
```

**Pros:**

- Quick iterations (edit files directly)
- Easy debugging (source code visible)
- No build time
- No internet dependency after initial clone

**Cons:**

- Source code on server (security risk)
- Environment differences (pip versions, OS, Python version)
- Manual steps (migrate, collectstatic, restart)
- Hard to scale (must setup each server)

**When to use:**

- Small hobby projects
- When you need frequent debugging on production (not recommended!)
- Team unfamiliar with Docker
- Limited resources (smaller VPS)

### Option 2: Hybrid Approach

Use Docker locally, traditional deployment on server:

```bash
# Local (Docker for consistency)
docker compose up

# Server (traditional for flexibility)
git pull && python manage.py migrate && systemctl restart gunicorn
```

**Pros:**

- Best of both worlds
- Faster server-side iteration
- Docker benefits locally

**Cons:**

- Environment differences still exist
- More complex setup

### Option 3: Docker Build on Server

Build Docker image on the server instead of pulling:

```bash
# On server
git pull
docker compose up --build
```

**Pros:**

- No GHCR dependency
- Still containerized
- Faster (no pull)

**Cons:**

- Source code on server
- Build on production server (resource usage)
- Must have build tools on server

### Which Approach to Choose?

| Factor           | GHCR (Current) | Traditional | Hybrid   |
| ---------------- | -------------- | ----------- | -------- |
| Security         | ⭐⭐⭐⭐⭐     | ⭐⭐⭐      | ⭐⭐⭐⭐ |
| Ease of Scaling  | ⭐⭐⭐⭐⭐     | ⭐⭐        | ⭐⭐⭐   |
| Debugging        | ⭐⭐⭐         | ⭐⭐⭐⭐⭐  | ⭐⭐⭐⭐ |
| Deployment Speed | ⭐⭐⭐         | ⭐⭐⭐⭐    | ⭐⭐⭐⭐ |
| Consistency      | ⭐⭐⭐⭐⭐     | ⭐⭐⭐      | ⭐⭐⭐⭐ |
| Learning Curve   | ⭐⭐⭐         | ⭐⭐⭐⭐⭐  | ⭐⭐⭐   |

**Recommendation:**

- **Use GHCR approach (current)** for production, staging, and when scaling
- **Use local Docker** for development and testing
- **Consider traditional** only for very small projects or when Docker isn't available

---

## 🎓 Summary & Best Practices

### Key Takeaways

1. **Single source of truth:**
   - One docker-compose.yml (with comments for dev/prod)
   - One .env file approach
   - One DEPLOYMENT.md with everything

2. **Automated workflow:**
   - Push code → GitHub Actions builds → GHCR stores image
   - On server: `docker compose pull && docker compose up -d`
   - Migrations run automatically

3. **Migration strategy:**
   - Create locally → test → commit → push
   - Included in Docker image automatically
   - Applied on container start
   - Manual control available via `docker exec`

4. **Debugging approach:**
   - Logs first: `docker compose logs -f`
   - Container access: `docker exec -it backend bash`
   - Database access: `docker exec -it db psql`
   - Structured logging for production

### Recommended Workflow

**Development:**

```bash
# 1. Local development
docker compose up --build

# 2. Make changes, test locally

# 3. If new models, create migrations
docker exec backend python manage.py makemigrations

# 4. Test migrations locally
docker exec backend python manage.py migrate

# 5. Commit and push
git add .
git commit -m "Add feature"
git push origin main
```

**Deployment:**

```bash
# 6. Wait for GitHub Actions to build (2-5 min)

# 7. On server
cd ~/deploy
docker compose pull
docker compose up -d

# 8. Check logs
docker compose logs -f backend

# 9. Verify
curl http://YOUR-SERVER-IP:8000
```

**Monitoring:**

```bash
# Regular checks
docker compose ps
docker compose logs --tail=50 backend
docker system df
df -h
```

### When Things Go Wrong

1. **Check logs first:** `docker compose logs -f`
2. **Verify containers running:** `docker compose ps`
3. **Check database connection:** `docker exec backend python manage.py wait_for_db`
4. **Access container if needed:** `docker exec -it backend bash`
5. **Rollback if necessary:** Use previous image tag
6. **Restore database if needed:** From backup

### Security Checklist for Production

When ready for production (currently simplified):

- [ ] Generate strong SECRET_KEY (50+ characters)
- [ ] Set DEBUG=0
- [ ] Use strong database passwords
- [ ] Configure ALLOWED_HOSTS with your domain
- [ ] Setup HTTPS (nginx + Let's Encrypt)
- [ ] Don't expose database port (remove from ports in docker-compose.yml)
- [ ] Enable firewall (only 80, 443, 22)
- [ ] Regular backups (automated)
- [ ] Monitor logs and metrics
- [ ] Keep Docker and base images updated
- [ ] Use specific image tags (not just :latest) for critical deployments
- [ ] Implement proper logging (send to external service)
- [ ] Add health check endpoints
- [ ] Configure CORS properly (not ALLOW_ALL in production)

---

## 📞 Quick Reference

### Essential Commands

```bash
# Development
docker compose up --build        # Start dev environment
docker compose down              # Stop dev environment

# Deployment
docker compose pull              # Get latest image
docker compose up -d             # Start in background
docker compose restart backend   # Restart backend only

# Debugging
docker compose logs -f           # View logs
docker compose logs -f backend   # Backend logs only
docker compose ps                # Check status
docker exec -it backend bash     # Access backend

# Django
docker exec backend python manage.py migrate
docker exec backend python manage.py makemigrations
docker exec -it backend python manage.py createsuperuser
docker exec backend python manage.py shell

# Database
docker exec -it db psql -U produser -d proddb
docker exec db pg_dump -U produser proddb > backup.sql

# Maintenance
docker system prune -a           # Clean up unused resources
docker system df                 # Check disk usage
```

### File Locations

- **Local:** `.env` (create from `.env.example`)
- **Server:** `~/deploy/.env` and `~/deploy/docker-compose.yml`
- **Backups:** `~/deploy/backups/` (create this directory)
- **Images:** GHCR `ghcr.io/YOUR-USERNAME/test-ghcr-backend`

---

## 🚀 Next Steps

1. ✅ **Review this document** - Understand the workflow
2. ✅ **Test locally** - `docker compose up --build`
3. ✅ **Update docker-compose.yml** - Add your GitHub username
4. ✅ **Push to GitHub** - Let Actions build your image
5. ✅ **Setup server** - Follow Part 3 in DEPLOYMENT.md
6. ✅ **Deploy** - `docker compose pull && docker compose up -d`
7. ✅ **Monitor** - `docker compose logs -f`
8. ⏭️ **Add HTTPS** - Setup nginx + Let's Encrypt (when ready)
9. ⏭️ **Add monitoring** - Setup health checks and alerts
10. ⏭️ **Automate backups** - Add cron job for daily DB backups

---

**Questions?** Check [DEPLOYMENT.md](DEPLOYMENT.md) for detailed guides.

**Happy deploying! 🎉**
