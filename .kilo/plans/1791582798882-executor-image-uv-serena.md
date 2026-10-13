# Fix serena MCP (`uvx` not found) in kubeopencode

## Problem

OpenCode in the agent pod reports `serena: Executable not found in $PATH: "uvx"`.
The serena MCP server is spawned by OpenCode inside the **executor (worker)
container**, which is the default `ghcr.io/kubeopencode/kubeopencode-agent-devbox`
(Debian bookworm, python3/pip/pipx, `USER 1000:0`, `HOME=/tmp`). It has no
`uv`/`uvx`. The `agents/opencode` image in this repo is only the init container
(copies the binary to `/tools`) — changing it would have no effect.

## Decisions

- New custom executor image in this repo, layered `FROM ghcr.io/kubeopencode/kubeopencode-agent-devbox:latest` (matches "Option 1: Create Custom Executor" from upstream docs; keeps full toolchain).
- Bake `uv`/`uvx` **and** serena into the image at build time (user decision). MCP command becomes plain `serena` — fast startup, no runtime egress for serena itself.
- `attach` and `opencode` images stay unchanged (attach pods don't run MCP servers).

## Changes

### 1. `agents/devbox/Dockerfile` (new)

```dockerfile
FROM ghcr.io/kubeopencode/kubeopencode-agent-devbox:latest

USER root
ARG UV_VERSION=<latest uv release at implementation time>
ARG SERENA_VERSION=<latest serena git tag at implementation time>

# uv + uvx into /usr/local/bin (same pattern devbox already uses for pylsp)
RUN pip install --break-system-packages --no-cache-dir uv==${UV_VERSION}

# serena as a uv tool, binary on global PATH, shared tool venv readable by uid 1000
ENV UV_TOOL_DIR=/usr/local/share/uv/tools \
    UV_TOOL_BIN_DIR=/usr/local/bin
RUN uv tool install --python /usr/bin/python3 \
      --from "git+https://github.com/oraios/serena@${SERENA_VERSION}" serena \
 && uv --version && uvx --version && serena --help >/dev/null

USER 1000:0
```

Notes:
- Default umask 022 makes `/usr/local/share/uv/tools` world-readable/executable — required since the executor runs as `1000:0`.
- If serena has no usable release tag, pin by commit hash instead and record it in the image tag (see below).
- serena runtime needs (git, gopls/tsserver/pylsp LSPs, python3) are already present in devbox.

### 2. `.github/workflows/build.yml`

Add a `devbox` job (clone of the `opencode` job):
- `context: agents/devbox`, platforms `linux/amd64,linux/arm64`
- `build-args`: `UV_VERSION`, `SERENA_VERSION` (define both in job `env`)
- Tags: `ghcr.io/${{ github.repository_owner }}/kubeopencode-agent-devbox:latest` and `ghcr.io/.../kubeopencode-agent-devbox:uv${UV_VERSION}-serena${SERENA_VERSION}` (use a short ref — tag name or commit — if serena isn't tag-releasable)

### 3. `README.md`

Add the new image to the table (`kubeopencode-agent-devbox` — executor with uv/uvx + serena) and a "Bumping uv / serena" note (update `UV_VERSION`/`SERENA_VERSION` in `build.yml` + Dockerfile defaults, bump image tag in homelab agent spec).

### 4. Homelab repo (manual, outside this repo)

- `50_apps/kubeopencode/agents/agent.yaml`: set `spec.executorImage: ghcr.io/felixz92/kubeopencode-agent-devbox:<tag>`.
- In the opencode config (`spec.config` inline or `configRef` ConfigMap, whichever is used), change the serena MCP entry from `uvx --from git+https://github.com/oraios/serena serena start-mcp-server ...` to:
  - `command: "serena"`, `args: ["start-mcp-server", ...existing flags unchanged...]`
  - (`type: local` stays as-is)

## Validation

1. Local build: `docker build -t devbox-test agents/devbox` (set build-args).
2. Smoke test as the runtime user:
   `docker run --rm --user 1000:0 -e HOME=/tmp devbox-test sh -c 'uv --version && uvx --version && serena --help'`
3. MCP startup smoke test: `timeout 5 serena start-mcp-server --context defaults < /dev/null` (expect clean start/hang-until-timeout, not an error exit).
4. Push via CI, update homelab agent.yaml, restart Agent Deployment, run a small Task and confirm OpenCode status shows serena connected (no "Executable not found").

## Risks / Trade-offs

- `FROM ...devbox:latest` is a moving base (toolchain drift between rebuilds) — accepted; alternative is forking the full devbox Dockerfile (2–3 GB rebuild, more drift to manage). Weekly CI schedule already exists and only rebuilds on ARG changes for pinned images; note that `latest` base means weekly rebuilds will pick up upstream changes.
- `pip install --break-system-packages` matches upstream devbox's own pattern.
- `uvx` remains available in the image for any other uv-based MCP/tooling.

## Out of scope

- Changes to `agents/opencode` (init) and `agents/attach` images.
- Pre-installing serena language-server extras beyond what devbox already ships.
