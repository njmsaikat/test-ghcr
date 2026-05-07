# Template for Django Project

Common setup for django project as a template with GitHub Container Registry (GHCR) deployment support.

## Tech Stack

**Backend:** Django>=3.2.4,<3.3.0

**Database:** Postgres:latest

**Platform:** Docker

**Container Manage:** docker-compose

**CI/CD:** GitHub Actions → GHCR

## Features

✅ Docker-based development environment  
✅ PostgreSQL database with docker-compose  
✅ Production-ready Dockerfile with gunicorn  
✅ Automated builds via GitHub Actions  
✅ Push to GitHub Container Registry (GHCR)  
✅ Deploy without pulling source code on server  
✅ Automatic database migrations  
✅ Static file handling

## Run Locally

You can fork this repository or
click the `Use this template` button to customize.
Otherwise:

Clone the project

```bash
  git clone https://github.com/njmsaikat/django-postgres-setup-docker-compose.git
```

Go to the project directory

```bash
  cd django-postgres-setup-docker-compose
```

Run command

```bash
  docker-compose up --build
```

## Production Deployment

### Quick Start

See [QUICKSTART.md](QUICKSTART.md) for a fast 5-minute deployment guide.

### Complete Guide

See [DEPLOYMENT.md](DEPLOYMENT.md) for comprehensive deployment documentation including:

- Server setup
- GHCR configuration
- Migration handling
- Debugging procedures
- Rollback strategies
- Security best practices

### Deployment Overview

1. **Push code to GitHub** → GitHub Actions automatically builds and pushes Docker image to GHCR
2. **On server:** Pull image and run with docker-compose (no source code needed!)
3. **Migrations run automatically** on container startup

```bash
# On server
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d
```

That's it! No git clone, no pip install, no source code on the server.

## Used Ports

- Django runs on port `8000`

- Postgresql runs on port `5432`

## Environment Variables

### Development

All environment variables for the development environment are stored in directory

`.env/dev.env`

### Production

Copy `.env.prod.example` to `.env.prod` and configure for your server.

See [DEPLOYMENT.md](DEPLOYMENT.md) for details.

## Support

For support, email njmsaikat@gmail.com

## Authors

- [@Saikat Roy](https://www.github.com/njmsaikat)

## LICENSE

[![MIT License](https://img.shields.io/apm/l/atomic-design-ui.svg?)](https://github.com/tterb/atomic-design-ui/blob/master/LICENSEs)
