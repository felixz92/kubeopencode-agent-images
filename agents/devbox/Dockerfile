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

# Versions (kept in sync with .github/workflows/build.yml env)
ARG UV_VERSION=0.13.0
ARG SERENA_VERSION=v1.7.0
# golangci-lint: present in the upstream image but not on PATH; rebuilt from
# source into /usr/local/bin. https://golangci-lint.run/docs/welcome/install/local/#install-from-sources
ARG GOLANGCI_LINT_VERSION=v2.14.0
# templ (a-h/templ): https://templ.guide/quick-start/installation
ARG TEMPL_VERSION=v0.3.977
# forgejo-mcp (git.b4mad.industries/agentic-forges/forgejo-mcp), prebuilt release binary
ARG FORGEJO_MCP_VERSION=v3.2.0
# open-code-review (https://github.com/alibaba/open-code-review) via npm
ARG OPEN_CODE_REVIEW_VERSION=1.12.13
# openspec (https://github.com/Fission-AI/OpenSpec) via npm
ARG OPENSPEC_VERSION=1.13.2
# Reinstall newer toolchains than the upstream image ships:
# Go from the official release tarball, Node from NodeSource (apt)
ARG GO_VERSION=1.26.9
ARG NODE_VERSION=26

# Pinned by digest (resolved from ghcr.io/kubeopencode/kubeopencode-agent-devbox:latest
# at build time). Bump deliberately when bumping UV_VERSION/SERENA_VERSION.
FROM ghcr.io/kubeopencode/kubeopencode-agent-devbox:latest@sha256:4b2457c65e24b6485dfb5caf07dca2b9efd8b2098e46e4dbaedc7f5f10d6c102

# Versions are declared as global ARGs above; re-declare the ones used below.
ARG UV_VERSION
ARG SERENA_VERSION
ARG GOLANGCI_LINT_VERSION
ARG TEMPL_VERSION
ARG FORGEJO_MCP_VERSION
ARG OPEN_CODE_REVIEW_VERSION
ARG OPENSPEC_VERSION
ARG GO_VERSION
ARG NODE_VERSION

# The base image switches to USER 1000:0; installs need root
USER root

# Go: reinstall from the official release tarball (upstream image ships an
# older Go). Replaces /usr/local/go in place so PATH stays unchanged.
# https://go.dev/doc/install
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    rm -rf /usr/local/go; \
    curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${arch}.tar.gz" \
      | tar -xz -C /usr/local

# Node: reinstall via NodeSource apt repository (upstream image ships an
# older distro node)
RUN set -eux; \
    curl -fsSL "https://deb.nodesource.com/setup_${NODE_VERSION}.x" | bash -; \
    apt-get install -y --no-install-recommends nodejs ripgrep; \
    rm -rf /var/lib/apt/lists/*

# uv + uvx into /usr/local/bin
# (--break-system-packages matches the pattern the devbox image itself uses
# for pylsp on Debian bookworm)
RUN pip install --break-system-packages --no-cache-dir uv==${UV_VERSION}

# Task (go-task) via the official Cloudsmith apt repository
# https://taskfile.dev/docs/installation#apt
RUN set -eux; \
    curl -1sLf 'https://dl.cloudsmith.io/public/task/task/setup.deb.sh' | bash; \
    apt-get update; \
    apt-get install -y --no-install-recommends task; \
    rm -rf /var/lib/apt/lists/*

# golangci-lint: prebuilt release binary onto the global PATH.
# (Building from source segfaults in go's assembler under QEMU/Rosetta when
# cross-building multi-arch, so we use the official release tarball instead:
# https://golangci-lint.run/docs/welcome/install/local/#install-from-binary-releases)
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    ver="${GOLANGCI_LINT_VERSION#v}"; \
    curl -fsSL "https://github.com/golangci/golangci-lint/releases/download/${GOLANGCI_LINT_VERSION}/golangci-lint-${ver}-linux-${arch}.tar.gz" \
      | tar -xz --strip-components=1 -C /usr/local/bin "golangci-lint-${ver}-linux-${arch}/golangci-lint"

# templ: prebuilt release binary onto the global PATH
# (same emulation concern as golangci-lint; templ ships release binaries)
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "${arch}" in amd64) tarch=x86_64 ;; arm64) tarch=arm64 ;; esac; \
    curl -fsSL "https://github.com/a-h/templ/releases/download/${TEMPL_VERSION}/templ_Linux_${tarch}.tar.gz" \
      | tar -xz -C /usr/local/bin templ

# forgejo-mcp: prebuilt release binary onto the global PATH
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    curl -fsSL "https://git.b4mad.industries/agentic-forges/forgejo-mcp/releases/download/${FORGEJO_MCP_VERSION}/forgejo-mcp_${FORGEJO_MCP_VERSION#v}_linux_${arch}.tar.gz" \
      | tar -xz --strip-components=1 -C /usr/local/bin "forgejo-mcp_${FORGEJO_MCP_VERSION#v}_linux_${arch}/forgejo-mcp"

# open-code-review: global npm package (npm was installed above).
# Binary on PATH is `ocr`.
RUN npm install -g @alibaba-group/open-code-review@${OPEN_CODE_REVIEW_VERSION}

# openspec: global npm package. Binary on PATH is `openspec`.
RUN npm install -g @fission-ai/openspec@${OPENSPEC_VERSION}

# serena as a uv tool: tool venv lives in a shared, world-readable location,
# the `serena` launcher binary goes on the global PATH so it works for the
# non-root runtime user (HOME=/tmp, UID 1000:0)
ENV UV_TOOL_DIR=/usr/local/share/uv/tools \
    UV_TOOL_BIN_DIR=/usr/local/bin
# Pin serena by commit hash (v1.7.0 = 949a27ef1e5fda1a6e7b561e777bcece345c6ffd);
# git tags are mutable, commits are not.
RUN uv tool install --python /usr/bin/python3 \
      --from "git+https://github.com/oraios/serena@949a27ef1e5fda1a6e7b561e777bcece345c6ffd" serena-agent

# Sanity checks + record versions.
# HOME=/root so serena's state dir isn't created root-owned under the shared /tmp
# (the base image sets HOME=/tmp for the OpenShift-compatible runtime user).
RUN set -eux; \
    export HOME=/root; \
    uv --version; \
    uvx --version; \
    serena --help >/dev/null; \
    task --version; \
    golangci-lint version; \
    templ version; \
    go version; \
    node --version; \
    forgejo-mcp --help >/dev/null; \
    ocr --help >/dev/null; \
    openspec --version; \
    echo "uv ${UV_VERSION} / serena ${SERENA_VERSION} / golangci-lint ${GOLANGCI_LINT_VERSION} / templ ${TEMPL_VERSION} / forgejo-mcp ${FORGEJO_MCP_VERSION} / open-code-review ${OPEN_CODE_REVIEW_VERSION} / openspec ${OPENSPEC_VERSION} / go ${GO_VERSION} / node ${NODE_VERSION}" > /image-extra-versions; \
    rm -rf /tmp/.serena /tmp/.cache/uv

# Restore the base image's non-root runtime user
USER 1000:0
