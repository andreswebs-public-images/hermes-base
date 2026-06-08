# syntax=docker/dockerfile:1
FROM docker.io/node:26-trixie

ARG DEBIAN_FRONTEND="noninteractive"
ARG DEBCONF_NONINTERACTIVE_SEEN="true"
ARG PYTHON_VERSION="3.14"

ENV PYTHONUNBUFFERED="1"
ENV UV_PYTHON_INSTALL_DIR="/opt/uv/python"
ENV UV_PYTHON_BIN_DIR="/usr/local/bin"

COPY --from=mikefarah/yq /usr/bin/yq /usr/local/bin/
COPY --from=denoland/deno:bin /deno /usr/local/bin/
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/
COPY --from=oven/bun:1 /usr/local/bin/bun /usr/local/bin/bunx /usr/local/bin/
COPY --from=golang:1.26-alpine /usr/local/go/ /usr/local/go/
COPY --from=golangci/golangci-lint:latest-alpine /usr/bin/golangci-lint /usr/local/bin/

RUN <<EOT
    set -o errexit
    apt-get update
    apt-get install --yes --no-install-recommends \
        bash-completion \
        bc \
        bzip2 \
        ca-certificates \
        curl \
        direnv \
        dnsutils \
        ffmpeg \
        file \
        gh \
        git \
        gnupg \
        htop \
        jq \
        less \
        lsof \
        man-db \
        netcat-openbsd \
        openssh-client \
        poppler-utils \
        procps \
        psmisc \
        ripgrep \
        rsync \
        shellcheck \
        shelltestrunner \
        socat \
        sudo \
        tree \
        tmux \
        unzip \
        vim \
        zip
    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOT

RUN touch /var/lib/hermes-tools-provisioned

ARG APP_UID="970"
ARG APP_GID="970"
ARG APP_USER="hermes"

RUN <<EOT
    set -o errexit
    groupadd \
        --gid "${APP_GID}" "${APP_USER}"
    useradd \
        --gid "${APP_GID}" \
        --uid "${APP_UID}" \
        --comment "" \
        --shell /bin/bash \
        --create-home \
        "${APP_USER}"
EOT

RUN uv python install "${PYTHON_VERSION}" --default

RUN <<EOT
    set -o errexit
    mkdir --parents /etc/sudoers.d/
    echo "${APP_USER} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${APP_USER}"
    chmod 0440 "/etc/sudoers.d/${APP_USER}"
EOT

ENV LANG="C.UTF-8"
ENV HOME="/home/${APP_USER}"
ENV EDITOR="vim"
ENV DO_NOT_TRACK="true"

RUN <<EOT
    set -o errexit
    cat > /etc/profile.d/dev-path.sh <<'SH'
export PATH="${HOME}/.venv/bin:${HOME}/.local/bin:${HOME}/.npm-global/bin:${HOME}/.bun/bin:${HOME}/go/bin:/usr/local/go/bin:${PATH}"
export NPM_CONFIG_PREFIX="${HOME}/.npm-global"
SH
    chmod 0644 /etc/profile.d/dev-path.sh
EOT
