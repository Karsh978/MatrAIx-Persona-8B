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

WORKDIR /root/project/MatrAIx-Persona-8B

# Install system dependencies & uv package manager
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/astral-sh/uv:0.9.26 /uv /uvx /bin/

# Copy full repository source context
COPY . .

# Copy compiled frontend static files
COPY --from=frontend-builder /app/frontend/dist ./application/playground/backend/static

WORKDIR /root/project/MatrAIx-Persona-8B

# Install dependencies and local repository in editable mode
RUN uv pip install --system -r application/playground/backend/requirements.txt || pip install -r application/playground/backend/requirements.txt
RUN pip install -e . --no-deps

WORKDIR /root/project/MatrAIx-Persona-8B/application/playground/backend

ENV PORT=8000
ENV OPENAI_BASE_URL=https://openrouter.ai/api/v1
EXPOSE ${PORT}

CMD ["python", "-m", "uvicorn", "api.app:app", "--host", "0.0.0.0", "--port", "8000"]
