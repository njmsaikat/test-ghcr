# docker/backend/Dockerfile
FROM python:3.8-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY ./backend/requirements.txt /app/backend/
RUN pip install --upgrade pip && \
    pip install -r backend/requirements.txt && \
    pip install gunicorn

# Copy application code
COPY ./backend /app/backend

WORKDIR /app/backend

EXPOSE 8000

# Default command (can be overridden in docker-compose)
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "3", "myproject.wsgi:application"]