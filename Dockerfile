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

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/astral-sh/uv:0.9.26 /uv /uvx /bin/

WORKDIR /app

# Copy backend source code directly
COPY application/playground/backend/ ./backend/

# Sync backend dependencies via uv / pip
RUN cd backend && (uv sync || pip install -r requirements.txt || pip install .)

COPY --from=frontend-builder /app/frontend/dist ./backend/static

# Render runtime configs & OpenRouter base URL
ENV PORT=8000
ENV OPENAI_BASE_URL=https://openrouter.ai/api/v1
EXPOSE ${PORT}

WORKDIR /app/backend
# Set PYTHONPATH to current backend directory and invoke Python entrypoint dynamically
ENV PYTHONPATH=/app/backend
CMD ["sh", "-c", "if [ -f main.py ]; then uv run uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}; elif [ -f run.py ]; then uv run python run.py; else uv run uvicorn server:app --host 0.0.0.0 --port ${PORT:-8000}; fi"]
