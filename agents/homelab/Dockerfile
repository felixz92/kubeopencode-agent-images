# KubeOpenCode Executor Image for Homelab Operations (Debian Bookworm)
#
# A standalone executor (worker) image for homelab ops tasks. OpenCode itself is
# provisioned at runtime by the kubeopencode-agent-opencode init container into
# /tools; this image ships the operating toolkit:
#
# - kubectl + krew with the cnpg and cert-manager plugins
# - Flux CLI
# - Terraform 1.16.5
# - talosctl 1.13.11
# - MCP servers (pre-installed binaries, no runtime download):
#   * containers/kubernetes-mcp-server
#   * controlplaneio-fluxcd/flux-operator (flux-operator-mcp)
#   * grafana/mcp-grafana
#   * VictoriaMetrics/mcp-victorialogs (VictoriaLogs MCP server)
#
# Base: debian:bookworm

FROM debian:bookworm-slim AS downloader

ARG KUBECTL_VERSION
ARG FLUX_VERSION
ARG TERRAFORM_VERSION
ARG TALOSCTL_VERSION
ARG K8S_MCP_VERSION
ARG FLUX_OPERATOR_MCP_VERSION
ARG MCP_GRAFANA_VERSION
ARG MCP_VICTORIALOGS_VERSION

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

ARG TARGETARCH
RUN set -eux; \
    case "${TARGETARCH}" in \
        amd64) karch=amd64; garch=x86_64 ;; \
        arm64) karch=arm64; garch=arm64 ;; \
        *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac; \
    mkdir -p /out; \
    # kubectl
    curl --retry 5 --retry-delay 3 --retry-all-errors -fsSL \
      "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${karch}/kubectl" \
      -o /out/kubectl; \
    # Flux CLI
    curl --retry 5 --retry-delay 3 --retry-all-errors -fsSL \
      "https://github.com/fluxcd/flux2/releases/download/v${FLUX_VERSION}/flux_${FLUX_VERSION}_linux_${karch}.tar.gz" \
      | tar -xz -C /out flux; \
    # Terraform
    curl --retry 5 --retry-delay 3 --retry-all-errors -fsSL \
      "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${karch}.zip" \
      -o /tmp/terraform.zip; \
    unzip /tmp/terraform.zip -d /out; \
    # talosctl
    curl --retry 5 --retry-delay 3 --retry-all-errors -fsSL \
      "https://github.com/siderolabs/talos/releases/download/v${TALOSCTL_VERSION}/talosctl-linux-${karch}" \
      -o /out/talosctl; \
    # kubernetes-mcp-server (raw binary asset)
    curl --retry 5 --retry-delay 3 --retry-all-errors -fsSL \
      "https://github.com/containers/kubernetes-mcp-server/releases/download/v${K8S_MCP_VERSION}/kubernetes-mcp-server-linux-${karch}" \
      -o /out/kubernetes-mcp-server; \
    # flux-operator-mcp
    curl --retry 5 --retry-delay 3 --retry-all-errors -fsSL \
      "https://github.com/controlplaneio-fluxcd/flux-operator/releases/download/v${FLUX_OPERATOR_MCP_VERSION}/flux-operator-mcp_${FLUX_OPERATOR_MCP_VERSION}_linux_${karch}.tar.gz" \
      | tar -xz -C /out flux-operator-mcp; \
    # mcp-grafana
    curl --retry 5 --retry-delay 3 --retry-all-errors -fsSL \
      "https://github.com/grafana/mcp-grafana/releases/download/v${MCP_GRAFANA_VERSION}/mcp-grafana_Linux_${garch}.tar.gz" \
      | tar -xz -C /out mcp-grafana; \
    # mcp-victorialogs
    curl --retry 5 --retry-delay 3 --retry-all-errors -fsSL \
      "https://github.com/VictoriaMetrics/mcp-victorialogs/releases/download/v${MCP_VICTORIALOGS_VERSION}/mcp-victorialogs_Linux_${garch}.tar.gz" \
      | tar -xz -C /out mcp-victorialogs; \
    chmod +x /out/*

FROM debian:bookworm

ARG KUBECTL_VERSION
ARG FLUX_VERSION
ARG TERRAFORM_VERSION
ARG TALOSCTL_VERSION
ARG K8S_MCP_VERSION
ARG FLUX_OPERATOR_MCP_VERSION
ARG MCP_GRAFANA_VERSION
ARG MCP_VICTORIALOGS_VERSION
# krew: single-arch tool, asset naming differs from GOARCH for amd64
ARG KREW_VERSION=v0.5.0

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      git \
      unzip \
      jq \
      bash-completion \
    ; \
    rm -rf /var/lib/apt/lists/*

COPY --from=downloader /out/* /usr/local/bin/

# kubectl shell completion for the default user
RUN set -eux; \
    kubectl completion bash > /etc/bash_completion.d/kubectl

# krew + kubectl plugins (cnpg, cert-manager) into a shared KREW_ROOT so the
# plugins work for the non-root runtime user too.
# https://krew.sigs.k8s.io/docs/user-guide/setup/install/
RUN set -eux; \
    case "$(dpkg --print-architecture)" in \
        amd64) karch=amd64 ;; \
        arm64) karch=arm64 ;; \
    esac; \
    export KREW_ROOT=/usr/local/krew; \
    curl --retry 5 --retry-delay 3 --retry-all-errors -fsSL \
      "https://github.com/kubernetes-sigs/krew/releases/download/${KREW_VERSION}/krew-linux_${karch}.tar.gz" \
      -o /tmp/krew.tar.gz; \
    tar -xzf /tmp/krew.tar.gz -C /tmp; \
    "/tmp/krew-linux_${karch}" install krew; \
    rm -f /tmp/krew.tar.gz "/tmp/krew-linux_${karch}"; \
    export PATH="${KREW_ROOT}/bin:${PATH}"; \
    kubectl krew install cnpg cert-manager; \
    rm -rf /var/lib/apt/lists/*

# Make krew-managed plugins discoverable on PATH for all processes
ENV KREW_ROOT=/usr/local/krew
ENV PATH=/usr/local/krew/bin:$PATH

# Non-root runtime user (OpenShift-compatible, mirrors the upstream devbox
# image convention: UID 1000, group 0, HOME under a writable dir)
RUN useradd -u 1000 -g 0 -m -s /bin/bash opencode
USER 1000:0
ENV HOME=/home/opencode

# Sanity checks
RUN set -eux; \
    kubectl version --client=true; \
    kubectl krew list; \
    flux --version; \
    terraform version; \
    talosctl version --client; \
    kubernetes-mcp-server --help >/dev/null; \
    flux-operator-mcp --help >/dev/null; \
    mcp-grafana --help >/dev/null; \
    # mcp-victorialogs initializes docs at startup (no --help path); only verify
    # the binary is executable and starts in stdio mode, then close its stdin
    VL_INSTANCE_ENTRYPOINT=http://localhost:9428 timeout 5 mcp-victorialogs </dev/null >/dev/null 2>&1 || true; \
    command -v mcp-victorialogs >/dev/null; \
    echo "kubectl v${KUBECTL_VERSION} / flux v${FLUX_VERSION} / terraform ${TERRAFORM_VERSION} / talosctl v${TALOSCTL_VERSION} / krew ${KREW_VERSION} / kubernetes-mcp-server v${K8S_MCP_VERSION} / flux-operator-mcp v${FLUX_OPERATOR_MCP_VERSION} / mcp-grafana v${MCP_GRAFANA_VERSION} / mcp-victorialogs v${MCP_VICTORIALOGS_VERSION}" \
      > /home/opencode/image-extra-versions
