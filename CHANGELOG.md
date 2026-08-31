# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

_(no unreleased changes yet)_

## [1.0.0] - 2026-08-31

First semver release. Brings this template to the fleet standard established
in [keycloak-traefik-letsencrypt-docker-compose](https://github.com/heyvaldemar/keycloak-traefik-letsencrypt-docker-compose)
v1.2.0.

### Security

- **GitLab bumped 17.7.2-ee → 19.3.1-ee** and **PostgreSQL 14 → 17**
  (GitLab 19.x requires PostgreSQL 17). ❗ Existing deployments cannot jump
  straight to these versions — see the release notes for the mandatory
  GitLab upgrade path and the database migration.
- **Traefik bumped 3.2 → 3.7** — Traefik 3.2's Docker client cannot talk
  to Docker Engine 29 (provider retry loop, silent 404s on current hosts).
- **All four images pinned by `tag@sha256:digest`.**
- **Credentials untracked from git.** The tracked `.env` carried
  generated-looking database and SMTP passwords published on GitHub —
  rotate them if your deployment reused them. `.env` is now gitignored and
  compose fails fast when required values are unset.

### Changed

- **Image pins live in the compose file as interpolation defaults**
  (`x-images` block): `git pull` alone delivers the tested version
  combination; `.env` carries only secrets, hostnames, and deliberate
  overrides.
- **SMTP is disabled by default** (`GITLAB_SMTP_ENABLED=false`); it was
  previously hardcoded on and required SMTP credentials to exist.
- README rebuilt to the fleet evaluator-first structure.

### Added

- **Deployment Verification workflow**: actionlint; Trivy scans of all
  four pinned images; weekly `check-pin-freshness` (digest drift + GitLab
  and Traefik release lag); deploy-and-test that boots the full stack
  with ephemeral credentials, waits through GitLab's first-boot
  reconfigure and database migrations, and requires the sign-in page to
  answer 200 through Traefik.

[Unreleased]: https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/releases/tag/v1.0.0
