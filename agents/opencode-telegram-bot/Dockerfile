# OpenCode Telegram Bot
#
# Builds https://github.com/grinev/opencode-telegram-bot from source, pinned to
# an upstream commit. Upstream's GHCR package is private (anonymous pulls get
# 403), so we maintain our own image.
#
# Deployed as a standalone bot Deployment per agent (not a sidecar); talks to
# the agent's persistent `opencode serve` via the controller-created Service.

ARG NODE_VERSION=22

FROM node:${NODE_VERSION}-bookworm-slim AS source

ARG OTB_COMMIT=2801cb8c5d703d7c45f830c1c74a8805355e5749

RUN set -ex; \
    apt-get update && apt-get install -y --no-install-recommends git ca-certificates \
    && rm -rf /var/lib/apt/lists/*; \
    git clone https://github.com/grinev/opencode-telegram-bot.git /src; \
    git -C /src checkout "${OTB_COMMIT}"

FROM node:${NODE_VERSION}-bookworm-slim AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    make \
    g++ \
    && rm -rf /var/lib/apt/lists/*

COPY --from=source /src/package.json /src/package-lock.json ./
RUN npm ci

COPY --from=source /src/tsconfig.json ./
COPY --from=source /src/src/ ./src/
RUN npm run build && npm prune --omit=dev

FROM node:${NODE_VERSION}-bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    dumb-init \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ENV NODE_ENV=production
ENV OPENCODE_TELEGRAM_HOME=/app/data

WORKDIR /app

RUN mkdir -p /app/data/logs /app/data/run && \
    chown -R node:node /app

COPY --from=builder --chown=node:node /app/dist ./dist
COPY --from=builder --chown=node:node /app/node_modules ./node_modules
COPY --from=builder --chown=node:node /app/package.json ./package.json

USER node

HEALTHCHECK --interval=30s --timeout=10s --start-period=45s --retries=3 \
    CMD ["node", "dist/runtime/healthcheck.js"]

ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "dist/index.js"]
