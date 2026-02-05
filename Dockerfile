FROM node:22-bookworm

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    procps \
    python3 \
    build-essential \
  && rm -rf /var/lib/apt/lists/*

RUN npm install -g openclaw@latest

WORKDIR /app

COPY package.json pnpm-lock.yaml ./
RUN corepack enable && pnpm install --frozen-lockfile --prod

COPY src ./src

RUN useradd -m -s /bin/bash openclaw \
  && chown -R openclaw:openclaw /app \
  && mkdir -p /data/.openclaw /data/workspace \
  && chown -R openclaw:openclaw /data

ENV PORT=8080
ENV HOME=/home/openclaw
ENV OPENCLAW_ENTRY=/usr/local/lib/node_modules/openclaw/dist/entry.js
ENV OPENCLAW_STATE_DIR=/data/.openclaw
ENV OPENCLAW_WORKSPACE_DIR=/data/workspace
EXPOSE 8080

# Health check: wait 60s for server to start, then check every 30s
# Railway also uses railway.toml healthcheckPath=/setup/healthz with 300s timeout
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s \
  CMD curl -f http://localhost:${PORT:-8080}/setup/healthz || exit 1

USER openclaw
CMD ["node", "src/server.js"]
