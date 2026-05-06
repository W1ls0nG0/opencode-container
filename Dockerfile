FROM alpine:3.21

RUN apk add --no-cache \
    bash \
    git \
    ripgrep \
    python3 \
    curl \
    jq \
    make \
    sqlite

ARG OPENCODE_VERSION=1.14.39
RUN curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path --version ${OPENCODE_VERSION} \
    && mv /root/.opencode/bin/opencode /usr/local/bin/opencode \
    && rm -rf /root/.opencode

RUN adduser -D -u 1000 sandbox \
    && mkdir -p /home/sandbox/.local/share/opencode \
               /home/sandbox/.local/state/opencode \
    && chown -R sandbox:sandbox /home/sandbox/.local

USER sandbox
WORKDIR /workspace
ENTRYPOINT ["opencode"]
