# KubeOpenCode Lightweight Attach Image
#
# Fork of https://github.com/kubeopencode/kubeopencode/tree/main/agents/attach
# bundling a newer OpenCode version (upstream pins 1.17.11; the free tier
# `opencode/big-pickle` requires OpenCode >= 1.18.0).
#
# Used for Server-mode --attach Pods: runs `opencode run --attach <server-url> "task"`.
# Only needs the OpenCode binary and network access - no development tools required.

FROM debian:bookworm-slim AS downloader

ARG OPENCODE_VERSION=1.18.35

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ARG TARGETARCH
RUN set -ex; \
    case "${TARGETARCH}" in \
        amd64) ARCH="x64" ;; \
        arm64) ARCH="arm64" ;; \
        *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac; \
    FILENAME="opencode-linux-${ARCH}.tar.gz"; \
    URL="https://github.com/anomalyco/opencode/releases/download/v${OPENCODE_VERSION}/${FILENAME}"; \
    echo "Downloading OpenCode v${OPENCODE_VERSION} from ${URL}..."; \
    curl --retry 5 --retry-delay 3 --retry-all-errors -fsSL "${URL}" -o /tmp/opencode.tar.gz; \
    tar -xzf /tmp/opencode.tar.gz -C /tmp; \
    mv /tmp/opencode /usr/local/bin/opencode; \
    chmod +x /usr/local/bin/opencode; \
    rm -f /tmp/opencode.tar.gz; \
    /usr/local/bin/opencode --version

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=downloader /usr/local/bin/opencode /usr/local/bin/opencode

ARG WORKSPACE_DIR=/workspace
ENV WORKSPACE_DIR=${WORKSPACE_DIR}
RUN mkdir -p ${WORKSPACE_DIR} && chmod 777 ${WORKSPACE_DIR}

# Match the init container pattern (/tools/opencode)
RUN mkdir -p /tools && chmod 777 /tools

USER 1000:0

WORKDIR ${WORKSPACE_DIR}

ENTRYPOINT ["/usr/local/bin/opencode"]
