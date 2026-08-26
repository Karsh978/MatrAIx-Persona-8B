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

# Sync dependencies into system environment
RUN uv pip install --system -r requirements.txt || pip install -r requirements.txt || pip install .

# Inject paths permanently into Python site-packages (.pth)
RUN python -c "import site; p = site.getsitepackages()[0] + '/matraix_paths.pth'; open(p, 'w').write('/root/project/MatrAIx-Persona-8B\n/root/project/MatrAIx-Persona-8B/application\n/root/project/MatrAIx-Persona-8B/application/playground\n/root/project/MatrAIx-Persona-8B/application/playground/backend\n')"

ENV PYTHONPATH=/root/project/MatrAIx-Persona-8B/application/playground:/root/project/MatrAIx-Persona-8B/application:/root/project/MatrAIx-Persona-8B:/root/project/MatrAIx-Persona-8B/application/playground/backend
ENV PORT=8000
ENV OPENAI_BASE_URL=https://openrouter.ai/api/v1
EXPOSE ${PORT}

# Run uvicorn with explicit sys.path setup for both 'playground' and 'backend'
CMD ["sh", "-c", "python -c \"import sys; sys.path.insert(0, '/root/project/MatrAIx-Persona-8B/application/playground'); sys.path.insert(0, '/root/project/MatrAIx-Persona-8B/application'); sys.path.insert(0, '/root/project/MatrAIx-Persona-8B/application/playground/backend'); import uvicorn; uvicorn.run('api.app:app', host='0.0.0.0', port=int('${PORT}'))\""]
