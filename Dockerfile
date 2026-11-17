# syntax=docker/dockerfile:1

# Development image only. majordomo ships as a static binary that runs on the
# host under systemd, built by release.yml, so there is no runtime image here.
# This file exists for compose.yaml and the devcontainer.

ARG RUST_VERSION=1.98
ARG DEBIAN_RELEASE=bookworm

# ---------- toolchain: the pinned toolchain, cached once ----------
FROM rust:${RUST_VERSION}-slim-${DEBIAN_RELEASE} AS toolchain
WORKDIR /app
# rust-toolchain.toml asks for `stable`, which is not the name the base image
# registers its toolchain under, so the first cargo call would trigger a rustup
# download. Do it here, once, in a layer that is cached for the dev stage.
COPY rust-toolchain.toml ./
RUN rustup show

# ---------- dev: full toolchain for compose and the devcontainer ----------
# The cargo install is slow, which is exactly why it is its own cached layer and
# not something contributors run by hand.
FROM toolchain AS dev
# Deliberately unpinned: pinning apt versions breaks the build at every Debian
# point release, and this image never ships.
# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install -y --no-install-recommends git pkg-config libssl-dev \
    && rm -rf /var/lib/apt/lists/*
RUN cargo install --locked just cargo-nextest cargo-watch cargo-deny cargo-audit
# Kept as a separate layer on purpose: the cargo install above takes minutes and
# this takes seconds, so adding a component later must not rebuild the slow one.
# hadolint ignore=DL3059
RUN rustup component add rustfmt clippy rust-src rust-analyzer
WORKDIR /app
CMD ["bash"]
