# Django + PostgreSQL + Docker + GHCR

Simple Django project template with Docker deployment to GitHub Container Registry (GHCR).

---

## 🚀 Features

- ✅ **Dockerized Development** - Everything runs in containers
- ✅ **PostgreSQL Database** - Production-ready database
- ✅ **GHCR Deployment** - Push code → Auto-build → Deploy image
- ✅ **No Source Code on Server** - Pull Docker image only
- ✅ **Automatic Migrations** - Run on container start
- ✅ **Single .env File** - Simple configuration
- ✅ **One Command Deploy** - `docker compose up -d`

---

## 🏃 Quick Start - Development

```bash
# Clone repo
git clone https://github.com/YOUR-USERNAME/test-ghcr.git
cd test-ghcr

# Create environment file
cp .env.example .env

# Start development environment
docker compose up --build

# Visit http://localhost:8000
```

**That's it!** PostgreSQL and Django are running.

### Create Admin User

```bash
docker exec -it backend python manage.py createsuperuser
```

Visit: `http://localhost:8000/admin`

---

## 📦 Deployment to Production

**See [DEPLOYMENT.md](DEPLOYMENT.md) for complete guide.**

**Quick Overview:**

1. **Push to GitHub** → GitHub Actions builds image → Pushes to GHCR
2. **On server:** Pull image and run with docker-compose
3. **Done!** Migrations run automatically

```bash
# On server
docker compose pull
docker compose up -d
```

---

## 📁 Project Structure

```
test-ghcr/
├── backend/              # Django application
│   ├── myproject/        # Django project settings
│   ├── myapp/           # Django app
│   ├── config/          # Configuration app
│   ├── manage.py
│   └── requirements.txt
├── docker/
│   └── backend/
│       └── Dockerfile   # Backend Docker image
├── .github/
│   └── workflows/
│       └── deploy-image.yml  # Auto-build on push
├── docker-compose.yml   # Single compose file (dev & prod)
├── .env.example         # Environment template
└── DEPLOYMENT.md        # Deployment guide
```

---

## 🔧 Configuration

### Environment Variables (.env file)

```bash
# Django
SECRET_KEY=your-secret-key
DEBUG=1                    # 1 for dev, 0 for prod
ALLOWED_HOSTS=localhost 127.0.0.1

# Database
DB_ENGINE=django.db.backends.postgresql
DB_NAME=mydb
DB_USER=admin
DB_PASSWORD=admin
DB_HOST=db
DB_PORT=5432
```

For production, use strong passwords and `DEBUG=0`.

---

## 🎯 Common Commands

### Development

```bash
# Start services
docker compose up

# Start in background
docker compose up -d

# Stop services
docker compose down

# View logs
docker compose logs -f

# Rebuild after code changes
docker compose up --build
```

### Django Commands

```bash
# Create superuser
docker exec -it backend python manage.py createsuperuser

# Make migrations
docker exec backend python manage.py makemigrations

# Apply migrations
docker exec backend python manage.py migrate

# Django shell
docker exec -it backend python manage.py shell

# Collect static files
docker exec backend python manage.py collectstatic
```

### Database

```bash
# Access PostgreSQL
docker exec -it db psql -U admin -d mydb

# Backup database
docker exec db pg_dump -U admin mydb > backup.sql

# Restore database
cat backup.sql | docker exec -i db psql -U admin -d mydb
```

---

## 🌐 Ports

- **Backend:** http://localhost:8000
- **Database:** localhost:5432 (for external tools like pgAdmin)

---

## 📚 Tech Stack

- **Backend:** Django 3.2.4
- **Database:** PostgreSQL 14
- **Server:** Gunicorn (production)
- **Container:** Docker + Docker Compose
- **CI/CD:** GitHub Actions
- **Registry:** GitHub Container Registry (GHCR)

---

## 🔐 Security Notes

Current setup is simplified for development. For production:

- ✅ Use strong SECRET_KEY (50+ random characters)
- ✅ Set DEBUG=0
- ✅ Use strong database passwords
- ✅ Configure ALLOWED_HOSTS properly
- ✅ Setup HTTPS (nginx + Let's Encrypt)
- ✅ Don't expose database port externally
- ⚠️ **Never commit .env file to git** (already in .gitignore)

---

## 🤝 Contributing

1. Fork the repo
2. Create feature branch (`git checkout -b feature/amazing`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing`)
5. Open Pull Request

---

## 📖 Documentation

- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Complete deployment guide with GHCR
  - Local setup
  - Push to GHCR
  - Server deployment
  - Migration handling
  - Debugging
  - Rollback procedures
  - Pros & cons

---

## 🐛 Troubleshooting

**Container won't start?**

```bash
docker compose logs backend
```

**Database connection error?**

```bash
docker compose ps db
docker exec backend python manage.py wait_for_db
```

**Need to reset?**

```bash
docker compose down -v  # Remove volumes too
docker compose up --build
```

---

## 📝 License

MIT License - Use freely!

---

## 🙋 Support

- Check [DEPLOYMENT.md](DEPLOYMENT.md) for detailed guides
- Open an issue on GitHub
- Check Docker logs: `docker compose logs -f`

---

**Happy coding! 🎉**

See [DEPLOYMENT.md](DEPLOYMENT.md) for details.

## Support

For support, email njmsaikat@gmail.com

## Authors

- [@Saikat Roy](https://www.github.com/njmsaikat)

## LICENSE

[![MIT License](https://img.shields.io/apm/l/atomic-design-ui.svg?)](https://github.com/tterb/atomic-design-ui/blob/master/LICENSEs)
