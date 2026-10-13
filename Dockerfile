# Farm Safety Fullstack Dockerfile (Railway / Cloud Deployment)
# Stage 1: Build the React frontend
FROM node:20-alpine AS frontend-builder
WORKDIR /build

COPY frontend/package*.json ./
RUN npm ci || npm install

COPY frontend/ ./
RUN npm run build

# Stage 2: FastAPI Python Backend serving built Frontend & APIs
FROM python:3.11-slim
WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000 \
    STATIC_DIR=/app/static

# Install backend dependencies
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend application source
COPY backend/ /app/

# Copy compiled frontend from builder
COPY --from=frontend-builder /build/dist /app/static

# Expose default port
EXPOSE 8000

# Launch uvicorn listening on the cloud provider assigned $PORT
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}"]
