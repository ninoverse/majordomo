# majordomo

[![CI](https://github.com/ninoverse/majordomo/actions/workflows/ci.yml/badge.svg)](https://github.com/ninoverse/majordomo/actions/workflows/ci.yml)
[![Audit](https://github.com/ninoverse/majordomo/actions/workflows/audit.yml/badge.svg)](https://github.com/ninoverse/majordomo/actions/workflows/audit.yml)

The ninoverse platform's control plane. majordomo is one Rust binary on the
host: under systemd it runs as the daemon that provisions and deploys every
service, and the same binary is the `mdo` command.

The code arrives milestone by milestone. Until the first real crate lands,
`crates/example/` is a placeholder that keeps the workspace building.

## Daily commands

The `justfile` is the single source of truth for every command — CI and the
agent rules call these recipes rather than repeating cargo invocations.

```bash
just            # list every recipe
just ci         # all four merge gates — run before every commit
just build      # build all crates
just check      # type-check, faster than build
just watch      # re-check on save
just fmt        # format in place
just test       # nextest (or cargo test) plus doc-tests
just doc        # build and open workspace docs
just audit      # CVE check
just dist <target>  # the release binary for one target, as release.yml builds it
```

Install `just` and the auxiliary tools once per machine:

```bash
cargo install --locked just
just setup      # cargo-nextest, cargo-watch, cargo-deny, cargo-audit
```

No `just`? `.cargo/config.toml` defines `cargo lint`, `cargo fmt-check` and
`cargo check-all`. There is no `cargo ci` equivalent — a cargo alias can only
wrap a single subcommand, so run the four gates in sequence.

## Releases

Merging to `main` bumps `[workspace.package].version` from the subject of the
squash commit, which is the PR title, and pushes a matching tag.
`release.yml` builds the static `majordomo` binary for
`x86_64-unknown-linux-musl` from that tag and attaches it to the GitHub release
with a `SHA256SUMS`. [`.agents/commit-conventions.md`](.agents/commit-conventions.md)
says which subject cuts which release.

The workflows call reusable ones in
[`ninoverse/.github`](https://github.com/ninoverse/.github), pinned to a
released version that Renovate bumps.

## Dev container

```bash
docker compose up -d dev                     # start the dev container
docker compose exec dev just ci              # run the gates inside it
docker compose run --rm dev cargo build      # or one-shot commands
```

The image is for development only; majordomo itself does not run in a
container. `target/` and the cargo registry live in named volumes rather than
on the bind mount, which keeps build times sane on macOS and Windows.
`.devcontainer/` reuses the same `dev` stage, so VS Code or Codespaces gets the
pinned toolchain with `just`, nextest, deny and audit already built.

## `Cargo.lock` is committed

It makes CI reproducible, makes `--locked` meaningful, and lets `cargo audit`
report what is actually built. The MSRV job and every `--locked` build in CI
depend on it being present and current.

## Rule files

The agent rules are not written here. They are composed from
[`ninoverse/agent-config-sync`](https://github.com/ninoverse/agent-config-sync)
by `agentcfg`, at the version `.agentprofile.yml` pins:

| File | What it is |
|------|------------|
| `.agentprofile.yml` | This repo's value on each axis — language, deployment, concerns — and the `config_version` it pins. The only file in the list a human edits. |
| `AGENTS.md` | Everything loaded in every session, plus one index line per rule that is not. |
| `CLAUDE.md` | A two-line `@AGENTS.md` import, plus anything true only for Claude Code. |
| `.agents/*.md` | One file per on-demand rule. Agent-neutral. |
| `.claude/skills/` | The task rules again, as Claude Code skills — `/gates`, `/new-crate`, `/why`. |

After editing `.agentprofile.yml`, run `just agentcfg sync`; CI's
`agentcfg check` fails otherwise. To find which fragment a rule came from, run
`just agentcfg why "<phrase>"`. A change to a rule belongs upstream, or outside
the `<!-- agentcfg:start -->` / `<!-- agentcfg:end -->` markers for this
repository only.

`SECURITY.md`, `CODE_OF_CONDUCT.md` and the issue forms come from
[`ninoverse/.github`](https://github.com/ninoverse/.github), which GitHub serves
as the default to every repository in the organization.
