# OpenCode Tool Init Container
#
# Fork of https://github.com/kubeopencode/kubeopencode/tree/main/agents/opencode
# with a newer OpenCode version (upstream pins 1.17.11; the free tier
# `opencode/big-pickle` requires OpenCode >= 1.18.0).
#
# This minimal image provides the OpenCode CLI binary for copying to shared volumes.
# Used as an init container to provision OpenCode to work containers.
#
# Architecture:
#   Init Container (this image) → copies → /tools/opencode → Work Container uses it
#
# Binary Source:
#   Downloaded from GitHub Releases: https://github.com/anomalyco/opencode/releases
#   - Linux x64: opencode-linux-x64.tar.gz (glibc)
#   - Linux arm64: opencode-linux-arm64.tar.gz (glibc)

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
    mv /tmp/opencode /opencode; \
    chmod +x /opencode; \
    rm -f /tmp/opencode.tar.gz; \
    /opencode --version | tee /opencode-version

FROM alpine:3.24.1

ENV TOOLS_DIR=/tools
ENV OPENCODE_BIN=opencode

COPY --from=downloader /opencode /opencode
COPY --from=downloader /opencode-version /opencode-version
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
