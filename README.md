# kubeopencode-agent-images

Custom KubeOpenCode agent images with a newer OpenCode version.

Upstream (`ghcr.io/kubeopencode/kubeopencode-agent-*`) pins OpenCode `1.17.11`
(`agents/Makefile` in kubeopencode/kubeopencode), but the free tier model
`opencode/big-pickle` requires **OpenCode >= 1.18.0**. These images are forks of
the upstream Dockerfiles that download OpenCode `1.18.35`.

## Images

| Image | Purpose |
|-------|---------|
| `ghcr.io/felixz92/kubeopencode-agent-opencode` | Init container: copies OpenCode binary to `/tools` |
| `ghcr.io/felixz92/kubeopencode-agent-attach` | Lightweight Task Pod image for `--attach` mode |
| `ghcr.io/felixz92/kubeopencode-agent-devbox` | Executor (worker) image: upstream devbox + `uv`/`uvx` + pre-installed Serena MCP server |
| `ghcr.io/felixz92/kubeopencode-agent-homelab` | Executor (worker) image for homelab ops: Debian bookworm + kubectl/krew (cnpg, cert-manager plugins), Flux CLI, Terraform, talosctl, and pre-installed MCP servers (kubernetes-mcp-server, flux-operator-mcp, mcp-grafana, mcp-victorialogs) |
| `ghcr.io/felixz92/kubeopencode-telegram-bot` | Standalone [opencode-telegram-bot](https://github.com/grinev/opencode-telegram-bot) image (Telegram client for an agent's `opencode serve`) |

Tagged with the OpenCode version (`1.18.35`) and `latest`. Built for
`linux/amd64` and `linux/arm64` by GitHub Actions (`.github/workflows/build.yml`).

## opencode-telegram-bot image

Upstream's GHCR package is private (anonymous pulls get 403), so this repo
builds it from source, pinned to an upstream commit (`OTB_COMMIT` in
`.github/workflows/build.yml`). The image is tagged `latest` and with the full
commit SHA. To bump:

1. Pick a commit from https://github.com/grinev/opencode-telegram-bot/commits/main
2. Update `OTB_COMMIT` in `.github/workflows/build.yml` (and the Dockerfile `ARG`)
3. Update the image tag in the homelab Telegram bot Deployment (`50_apps/kubeopencode/agents/tpl-go-mocks-telegram-bot.yaml`)

## Devbox image versioning (imagePullPolicy issue)

KubeOpenCode does not support `imagePullPolicy: Always` for the executor
(devbox) image, so a mutable `:latest` tag is never refreshed on the cluster.
The devbox image is therefore additionally tagged with a unique, monotonically
increasing stamp per build:

```
uv<UV_VERSION>-serena<SERENA_VERSION>-<YYYYMMDD>-<run_number>
```

e.g. `uv0.13.0-serenav1.7.0-20261010-42`. Bumping this tag in the Agent spec
(`executorImage`) is what makes the cluster pull the new image. The current
stamp is printed in the build workflow summary/logs.

## Bumping uv / Serena (devbox image)

1. Check https://github.com/astral-sh/uv/releases and https://github.com/oraios/serena/tags
2. Update `UV_VERSION` / `SERENA_VERSION` in `.github/workflows/build.yml` (and the Dockerfile defaults)
3. Update the `executorImage` tag in the homelab Agent spec (`50_apps/kubeopencode/agents/agent.yaml`) to the new stamped tag

## Bumping Go / Node (devbox image)

The devbox image reinstalls Go and Node on top of the (older) upstream versions,
from `GO_VERSION` / `NODE_VERSION` in `.github/workflows/build.yml` (defaults
mirrored in `agents/devbox/Dockerfile`).

## Bumping OpenCode

1. Check https://github.com/anomalyco/opencode/releases
2. Update `OPENCODE_VERSION` in `.github/workflows/build.yml` (and the Dockerfile defaults)
3. Update the image tag in the homelab Agent spec (`50_apps/kubeopencode/agents/agent.yaml`)

## Homelab executor image (kubeopencode-agent-homelab)

Standalone Debian bookworm executor image (`agents/homelab/Dockerfile`) with
`kubectl` (+ krew with `cnpg` and `cert-manager` plugins), Flux CLI, Terraform,
talosctl, and the MCP servers `kubernetes-mcp-server`,
`flux-operator-mcp` (controlplaneio-fluxcd/flux-operator), `mcp-grafana`, and
`mcp-victorialogs` (VictoriaMetrics/mcp-victorialogs) pre-installed. Note: the
VictoriaLogs MCP server is `VictoriaMetrics/mcp-victorialogs` (not the retired
`VictoriaMetrics-Community/victorialogs-mcp` path) and requires
`VL_INSTANCE_ENTRYPOINT` to be set at runtime. OpenCode itself is provisioned
by the `kubeopencode-agent-opencode` init container into `/tools`. It is tagged
with the same monotonically increasing stamp scheme as the devbox image:

```
tf<TERRAFORM_VERSION>-talosctl<TALOSCTL_VERSION>-<YYYYMMDD>-<run_number>
```

### Bumping homelab image tools

1. Update `KUBECTL_VERSION` / `FLUX_VERSION` / `TERRAFORM_VERSION` /
   `TALOSCTL_VERSION` / `KREW_VERSION` / `K8S_MCP_VERSION` /
   `FLUX_OPERATOR_MCP_VERSION` / `MCP_GRAFANA_VERSION` /
   `MCP_VICTORIALOGS_VERSION` in `.github/workflows/build.yml`
   (defaults mirrored in `agents/homelab/Dockerfile`)
2. Update the `executorImage` tag in the homelab Agent spec to the new stamped tag

## Usage (homelab)

```yaml
spec:
  agentImage: ghcr.io/felixz92/kubeopencode-agent-opencode:1.18.35
  attachImage: ghcr.io/felixz92/kubeopencode-agent-attach:1.18.35
  executorImage: ghcr.io/felixz92/kubeopencode-agent-devbox:latest
```
