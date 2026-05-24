#https://hub.docker.com/_/python/tags?name=slim
FROM python:3.14-slim AS builder

RUN pip install --no-cache-dir uv
RUN mkdir -p /root/.cache/uv

COPY requirements.txt .
RUN uv pip install --system -r requirements.txt

FROM python:3.14-slim

RUN useradd -u 1000 -m appuser
ENV UV_CACHE_DIR=/home/appuser/.cache/uv

RUN mkdir -p /home/appuser/.cache/uv \
    && chown -R appuser:appuser /home/appuser

COPY --from=builder /usr/local /usr/local

WORKDIR /app
COPY . /app

USER appuser
EXPOSE 8800

CMD ["sh", "-c", "cd /app/www && python -m http.server 8800 --bind 0.0.0.0"]
