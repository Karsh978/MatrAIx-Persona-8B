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

# PERMANENT PATH FIX:
# 1. /application -> contains 'playground' directory (fixes 'from playground.harbor')
# 2. /application/playground -> contains 'backend' directory (fixes 'from backend.service')
# 3. /application/playground/backend -> backend source root
RUN python -c "import site; p = site.getsitepackages()[0] + '/matraix_persona.pth'; open(p, 'w').write('/root/project/MatrAIx-Persona-8B/application\n/root/project/MatrAIx-Persona-8B/application/playground\n/root/project/MatrAIx-Persona-8B/application/playground/backend\n/root/project/MatrAIx-Persona-8B\n')"

ENV PYTHONPATH=/root/project/MatrAIx-Persona-8B/application:/root/project/MatrAIx-Persona-8B/application/playground:/root/project/MatrAIx-Persona-8B/application/playground/backend:/root/project/MatrAIx-Persona-8B
ENV PORT=8000
ENV OPENAI_BASE_URL=https://openrouter.ai/api/v1
EXPOSE ${PORT}

# Launch via Python inline sys.path setup as a bulletproof double safety net
CMD ["sh", "-c", "python -c \"import sys; sys.path.extend(['/root/project/MatrAIx-Persona-8B/application', '/root/project/MatrAIx-Persona-8B/application/playground', '/root/project/MatrAIx-Persona-8B/application/playground/backend']); import uvicorn; uvicorn.run('api.app:app', host='0.0.0.0', port=int('${PORT}'))\""]
