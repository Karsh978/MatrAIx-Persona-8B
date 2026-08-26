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

# Deep path layout setup for pathlib parents[4] compatibility
WORKDIR /root/project/MatrAIx-Persona-8B

# Copy full repository source context
COPY . .

# Copy compiled frontend static files
COPY --from=frontend-builder /app/frontend/dist ./application/playground/backend/static

WORKDIR /root/project/MatrAIx-Persona-8B/application/playground/backend

# Install dependencies globally
RUN uv pip install --system -r requirements.txt || pip install -r requirements.txt || pip install .

# CORRECT SYMLINKS:
# 1. 'backend' points directly to backend directory -> Satisfies 'from backend.service'
# 2. 'playground' points to application/playground directory -> Satisfies 'from playground.harbor'
RUN PYTHON_SITE=$(python -c "import site; print(site.getsitepackages()[0])") && \
    rm -rf $PYTHON_SITE/backend $PYTHON_SITE/playground && \
    ln -s /root/project/MatrAIx-Persona-8B/application/playground/backend $PYTHON_SITE/backend && \
    ln -s /root/project/MatrAIx-Persona-8B/application/playground $PYTHON_SITE/playground

ENV PORT=8000
ENV OPENAI_BASE_URL=https://openrouter.ai/api/v1
EXPOSE ${PORT}

# Run FastAPI app directly
CMD ["sh", "-c", "python -m uvicorn api.app:app --host 0.0.0.0 --port ${PORT:-8000}"]
