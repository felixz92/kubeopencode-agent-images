# KubeOpenCode Executor Image with uv + Serena
#
# Layered on the upstream devbox image (full development environment) with:
# - uv / uvx (Astral) for Python tool management
# - Serena (semantic code intelligence MCP server) pre-installed as a uv tool
#
# This is the executor (worker) container image: it runs /tools/opencode and
# spawns MCP servers. The upstream devbox image ships no uv/uvx, which broke
# uvx-based MCP configs ("Executable not found in $PATH: uvx"); this image
# bakes both uv and serena in so MCP startup needs no runtime download.
#
# Base: https://github.com/kubeopencode/kubeopencode/tree/main/agents/devbox

FROM ghcr.io/kubeopencode/kubeopencode-agent-devbox:latest

# Versions (kept in sync with .github/workflows/build.yml env)
ARG UV_VERSION=0.13.0
ARG SERENA_VERSION=v1.7.0

# The base image switches to USER 1000:0; installs need root
USER root

# uv + uvx into /usr/local/bin
# (--break-system-packages matches the pattern the devbox image itself uses
# for pylsp on Debian bookworm)
RUN pip install --break-system-packages --no-cache-dir uv==${UV_VERSION}

# serena as a uv tool: tool venv lives in a shared, world-readable location,
# the `serena` launcher binary goes on the global PATH so it works for the
# non-root runtime user (HOME=/tmp, UID 1000:0)
ENV UV_TOOL_DIR=/usr/local/share/uv/tools \
    UV_TOOL_BIN_DIR=/usr/local/bin
RUN uv tool install --python /usr/bin/python3 \
      --from "git+https://github.com/oraios/serena@${SERENA_VERSION}" serena-agent

# Sanity checks + record versions.
# HOME=/root so serena's state dir isn't created root-owned under the shared /tmp
# (the base image sets HOME=/tmp for the OpenShift-compatible runtime user).
RUN set -eux; \
    export HOME=/root; \
    uv --version; \
    uvx --version; \
    serena --help >/dev/null; \
    echo "uv ${UV_VERSION} / serena ${SERENA_VERSION}" > /image-extra-versions; \
    rm -rf /tmp/.serena /tmp/.cache/uv

# Restore the base image's non-root runtime user
USER 1000:0
