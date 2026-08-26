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

# Deep path layout setup to fix pathlib parents[4] and module resolution
WORKDIR /root/project/MatrAIx-Persona-8B

# Copy entire repository source context
COPY . .

# Copy compiled frontend static files
COPY --from=frontend-builder /app/frontend/dist ./application/playground/backend/static

WORKDIR /root/project/MatrAIx-Persona-8B/application/playground/backend

# Sync dependencies
RUN uv sync || pip install -r requirements.txt || pip install .

# Set complete python environment paths for root & inner submodules
ENV PYTHONPATH=/root/project/MatrAIx-Persona-8B:/root/project/MatrAIx-Persona-8B/application:/root/project/MatrAIx-Persona-8B/application/playground:/root/project/MatrAIx-Persona-8B/application/playground/backend
ENV PORT=8000
ENV OPENAI_BASE_URL=https://openrouter.ai/api/v1
EXPOSE ${PORT}

# Run FastAPI via app.py
CMD ["sh", "-c", "uv run uvicorn api.app:app --host 0.0.0.0 --port ${PORT:-8000}"]
