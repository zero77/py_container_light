#https://hub.docker.com/_/python/tags?name=slim
# Stage 1: Build Python deps
FROM python:3.14-slim AS builder

RUN pip install --no-cache-dir uv
RUN mkdir -p /root/.cache/uv

COPY requirements.txt .
RUN uv pip install --system -r requirements.txt

# Stage 2: Final runtime image
FROM python:3.14-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    tor \
    torsocks \
    tini \
    && rm -rf /var/lib/apt/lists/*

# Configure Tor (localhost only, no password)
RUN echo "SOCKSPort 9050" >> /etc/tor/torrc && \
    echo "ControlPort 9051" >> /etc/tor/torrc && \
    echo "CookieAuthentication 0" >> /etc/tor/torrc && \
    echo "HashedControlPassword \"\"" >> /etc/tor/torrc && \
    echo "DisableNetwork 0" >> /etc/tor/torrc && \
    echo "Log notice stdout" >> /etc/tor/torrc

RUN useradd -u 1000 -m appuser
ENV UV_CACHE_DIR=/home/appuser/.cache/uv

RUN mkdir -p /home/appuser/.cache/uv \
    && chown -R appuser:appuser /home/appuser

COPY --from=builder /usr/local /usr/local

WORKDIR /app
COPY . /app

USER appuser
EXPOSE 8800

ENTRYPOINT ["/usr/bin/tini", "--"]

CMD ["sh", "-c", "\
    tor & \
    sleep 5 && \
    cd /app/www && \
    python -m http.server 8800 --bind 0.0.0.0 \
"]
