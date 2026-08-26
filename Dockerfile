# syntax=docker/dockerfile:1

# --- Stage 1: Build React Frontend ---
FROM node:20-slim AS frontend-builder
WORKDIR /app/frontend

COPY application/playground/frontend/package*.json ./
RUN npm ci

COPY application/playground/frontend/ ./
RUN npm run build

# --- Stage 2: Final Production Runtime ---
FROM python:3.12-slim

# Install system dependencies & uv package manager
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/astral-sh/uv:0.9.26 /uv /uvx /bin/

# Create deep nested path structure to prevent pathlib parents[4] IndexError
WORKDIR /root/project/MatrAIx-Persona-8B/application/playground/backend

# Copy backend source code to the deep path
COPY application/playground/backend/ ./

# Sync backend dependencies
RUN uv sync || pip install -r requirements.txt || pip install .

# Copy compiled frontend static files to backend static folder
COPY --from=frontend-builder /app/frontend/dist ./static

# Configure PYTHONPATH to include parent directories so 'from backend...' imports work
ENV PYTHONPATH=/root/project/MatrAIx-Persona-8B/application/playground:/root/project/MatrAIx-Persona-8B/application/playground/backend
ENV PORT=8000
ENV OPENAI_BASE_URL=https://openrouter.ai/api/v1
EXPOSE ${PORT}

# Launch uvicorn targeting api package entrypoint dynamically
CMD ["sh", "-c", "if [ -f api/main.py ]; then uv run uvicorn api.main:app --host 0.0.0.0 --port ${PORT:-8000}; elif [ -f api/app.py ]; then uv run uvicorn api.app:app --host 0.0.0.0 --port ${PORT:-8000}; elif [ -f api/server.py ]; then uv run uvicorn api.server:app --host 0.0.0.0 --port ${PORT:-8000}; else uv run uvicorn api:app --host 0.0.0.0 --port ${PORT:-8000}; fi"]
