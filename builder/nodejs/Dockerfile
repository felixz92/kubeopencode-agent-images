# CI Executor Image (Node.js)
#
# A standalone executor (worker) image for CI tasks on Node.js projects.
# OpenCode itself is provisioned at runtime by the kubeopencode-agent-opencode
# init container into /tools; this image ships Node.js with npm plus:
#
# - open-code-review (ocr), global npm package
#
# Base: node:26-bookworm (Node major kept in sync with NODE_VERSION in
# .github/workflows/build.yml; Debian bookworm matches the golang builder)

# Versions (kept in sync with .github/workflows/build.yml env)
ARG NODE_VERSION=26
# open-code-review (https://github.com/alibaba/open-code-review) via npm
ARG OPEN_CODE_REVIEW_VERSION=1.12.13

FROM node:${NODE_VERSION}-bookworm

ARG OPEN_CODE_REVIEW_VERSION

# open-code-review: global npm package. Binary on PATH is `ocr`.
RUN npm install -g @alibaba-group/open-code-review@${OPEN_CODE_REVIEW_VERSION}

# Sanity checks + record versions
RUN set -eux; \
    node --version; \
    npm --version; \
    ocr --help >/dev/null; \
    echo "node $(node --version) / open-code-review ${OPEN_CODE_REVIEW_VERSION}" > /image-extra-versions
