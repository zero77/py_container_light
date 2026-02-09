FROM python:3.12-slim AS builder

# Install uv (ultra-fast Python package installer)
RUN pip install --no-cache-dir uv

# Create a directory for cached wheels
RUN mkdir -p /root/.cache/uv

# Install dependencies into system site-packages using uv
COPY requirements.txt .
RUN uv pip install --system -r requirements.txt

# Final stage
FROM python:3.12-slim

# Create non-root user with UID 1000 (matches docker-compose)
RUN useradd -u 1000 -m appuser

# Set uv cache directory for the non-root user
ENV UV_CACHE_DIR=/home/appuser/.cache/uv

# Ensure the cache directory exists and has correct permissions
RUN mkdir -p /home/appuser/.cache/uv && chown -R appuser:appuser /home/appuser

# Copy installed packages from builder
COPY --from=builder /usr/local /usr/local

WORKDIR /app
COPY . /app

# Switch to non-root user
USER appuser

EXPOSE 8800

CMD ["sh", "-c", "cd /app/www && python -m http.server 8800 --bind 0.0.0.0"]

