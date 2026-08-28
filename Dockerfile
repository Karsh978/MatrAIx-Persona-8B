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

# Setup Python site-packages path mapping via .pth file
# This resolves BOTH 'backend' and 'playground.harbor' globally without symlink ambiguity
RUN python -c "import site; p = site.getsitepackages()[0] + '/matraix_persona.pth'; open(p, 'w').write('/root/project/MatrAIx-Persona-8B/application/playground/backend\n/root/project/MatrAIx-Persona-8B/application\n/root/project/MatrAIx-Persona-8B\n')"

ENV PYTHONPATH=/root/project/MatrAIx-Persona-8B/application/playground/backend:/root/project/MatrAIx-Persona-8B/application:/root/project/MatrAIx-Persona-8B
ENV PORT=8000
ENV OPENAI_BASE_URL=https://openrouter.ai/api/v1
EXPOSE ${PORT}

# Direct FastAPI launch
CMD ["sh", "-c", "python -m uvicorn api.app:app --host 0.0.0.0 --port ${PORT:-8000}"]
