# CI Executor Image (Node.js)
#
# A standalone executor (worker) image for CI tasks on Node.js projects.
# OpenCode itself is provisioned at runtime by the kubeopencode-agent-opencode
# init container into /tools; this image ships Node.js with npm plus:
#
# - open-code-review (ocr), global npm package
# - open-code-review-forgejo (ocr-forgejo), static binary from releases
#
# Base: node:26-bookworm (Node major kept in sync with NODE_VERSION in
# .github/workflows/build.yml; Debian bookworm matches the golang builder)

# Versions (kept in sync with .github/workflows/build.yml env)
ARG NODE_VERSION=26
# open-code-review (https://github.com/alibaba/open-code-review) via npm
ARG OPEN_CODE_REVIEW_VERSION=1.12.13
# open-code-review-forgejo (https://github.com/felixz92/open-code-review-forgejo)
ARG OPEN_CODE_REVIEW_FORGEJO_VERSION=v0.2.0
# forgejo-mcp (git.b4mad.industries/agentic-forges/forgejo-mcp), prebuilt release binary
ARG FORGEJO_MCP_VERSION=v3.2.0

FROM node:${NODE_VERSION}-bookworm

ARG OPEN_CODE_REVIEW_VERSION
ARG OPEN_CODE_REVIEW_FORGEJO_VERSION

# open-code-review: global npm package. Binary on PATH is `ocr`.
RUN npm install -g @alibaba-group/open-code-review@${OPEN_CODE_REVIEW_VERSION}

# forgejo-mcp: prebuilt release binary onto the global PATH
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    curl -fsSL "https://git.b4mad.industries/agentic-forges/forgejo-mcp/releases/download/${FORGEJO_MCP_VERSION}/forgejo-mcp_${FORGEJO_MCP_VERSION#v}_linux_${arch}.tar.gz" \
      | tar -xz --strip-components=1 -C /usr/local/bin "forgejo-mcp_${FORGEJO_MCP_VERSION#v}_linux_${arch}/forgejo-mcp"

# open-code-review-forgejo: standalone binary from GitHub releases. Binary on
# PATH is `ocr-forgejo` (kept separate from `ocr`). Target arch is resolved
# from the base image's platform so the same Dockerfile works for amd64/arm64.
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
        amd64|arm64) ;; \
        *) echo "unsupported architecture: $arch" >&2; exit 1 ;; \
    esac; \
    curl -fsSL \
        "https://github.com/felixz92/open-code-review-forgejo/releases/download/${OPEN_CODE_REVIEW_FORGEJO_VERSION}/ocr-forgejo-linux-${arch}" \
        -o /usr/local/bin/ocr-forgejo; \
    chmod +x /usr/local/bin/ocr-forgejo

# Sanity checks + record versions
RUN set -eux; \
    node --version; \
    npm --version; \
    ocr --help >/dev/null; \
    ocr-forgejo -h >/dev/null 2>&1 || true; \
    echo "node $(node --version) / open-code-review ${OPEN_CODE_REVIEW_VERSION} / open-code-review-forgejo ${OPEN_CODE_REVIEW_FORGEJO_VERSION} / forgejo-mcp ${FORGEJO_MCP_VERSION}" > /image-extra-versions
