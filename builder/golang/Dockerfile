# CI Executor Image (Go)
#
# A standalone executor (worker) image for CI tasks on Go projects. OpenCode
# itself is provisioned at runtime by the kubeopencode-agent-opencode init
# container into /tools; this image ships the Go toolchain plus:
#
# - Task (go-task / Taskfile runner)
# - golangci-lint
#
# Base: golang:1.26-bookworm

# Versions (kept in sync with .github/workflows/build.yml env)
ARG TASK_VERSION=3.54.0
# golangci-lint: prebuilt release binary onto the global PATH.
# (Building from source segfaults in go's assembler under QEMU/Rosetta when
# cross-building multi-arch, so we use the official release tarball instead:
# https://golangci-lint.run/docs/welcome/install/local/#install-from-binary-releases)
ARG GOLANGCI_LINT_VERSION=v2.14.0

ARG NODE_VERSION=26
FROM golang:1.26-bookworm

ARG TASK_VERSION
ARG GOLANGCI_LINT_VERSION
ARG NODE_VERSION
ARG TARGETARCH

# Task (go-task): prebuilt release binary onto the global PATH
# https://taskfile.dev/docs/installation
RUN set -eux; \
    curl -fsSL "https://github.com/go-task/task/releases/download/v${TASK_VERSION}/task_linux_${TARGETARCH}.tar.gz" \
      | tar -xz -C /usr/local/bin task

# golangci-lint: prebuilt release binary onto the global PATH
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    ver="${GOLANGCI_LINT_VERSION#v}"; \
    curl -fsSL "https://github.com/golangci/golangci-lint/releases/download/${GOLANGCI_LINT_VERSION}/golangci-lint-${ver}-linux-${arch}.tar.gz" \
      | tar -xz --strip-components=1 -C /usr/local/bin "golangci-lint-${ver}-linux-${arch}/golangci-lint"

# Node: reinstall via NodeSource apt repository (upstream image ships an
# older distro node)
RUN set -eux; \
    curl -fsSL "https://deb.nodesource.com/setup_${NODE_VERSION}.x" | bash -; \
    apt-get install -y --no-install-recommends nodejs ripgrep; \
    rm -rf /var/lib/apt/lists/*

# Sanity checks + record versions
RUN set -eux; \
    go version; \
    task --version; \
    golangci-lint version; \
    echo "go $(go version | awk '{print $3}') / task ${TASK_VERSION} / golangci-lint ${GOLANGCI_LINT_VERSION} / node ${NODE_VERSION}" > /image-extra-versions
