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

Tagged with the OpenCode version (`1.18.35`) and `latest`. Built for
`linux/amd64` and `linux/arm64` by GitHub Actions (`.github/workflows/build.yml`).

## Bumping uv / Serena (devbox image)

1. Check https://github.com/astral-sh/uv/releases and https://github.com/oraios/serena/tags
2. Update `UV_VERSION` / `SERENA_VERSION` in `.github/workflows/build.yml` (and the Dockerfile defaults)
3. Update the `executorImage` tag in the homelab Agent spec (`50_apps/kubeopencode/agents/agent.yaml`)


## Bumping OpenCode

1. Check https://github.com/anomalyco/opencode/releases
2. Update `OPENCODE_VERSION` in `.github/workflows/build.yml` (and the Dockerfile defaults)
3. Update the image tag in the homelab Agent spec (`50_apps/kubeopencode/agents/agent.yaml`)

## Usage (homelab)

```yaml
spec:
  agentImage: ghcr.io/felixz92/kubeopencode-agent-opencode:1.18.35
  attachImage: ghcr.io/felixz92/kubeopencode-agent-attach:1.18.35
  executorImage: ghcr.io/felixz92/kubeopencode-agent-devbox:latest
```
