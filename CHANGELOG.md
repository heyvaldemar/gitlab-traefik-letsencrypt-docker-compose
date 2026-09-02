# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

_(no unreleased changes yet)_

## [1.3.0] - 2026-09-02

### Added

- **`gitlab-backup.sh`** — a cron-ready host script around the tool that
  actually knows GitLab: `gitlab-backup create STRATEGY=copy` (repos,
  database, uploads, registry, ...), copied out to `GITLAB_BACKUPS_PATH`
  (default `./backups`), plus a `tar.gz` of `/etc/gitlab` — `gitlab.rb`
  and `gitlab-secrets.json`, without which the backup cannot be
  decrypted. Every step logs `OK` or `FAILED`; files older than
  `GITLAB_BACKUP_PRUNE_DAYS` (default 7) are pruned. The README carries
  the timer line and the restore procedure.
- CI runs the script against the fresh instance and checks that both
  archives are readable and the config archive carries the secrets.

## [1.2.0] - 2026-09-02

### Added

- **Resource limits on every service, as `.env`-overridable defaults.**
  Each service now carries memory and CPU limits plus reservations
  (`<SERVICE>_MEMORY_LIMIT`, `_CPU_LIMIT`, `_MEMORY_RESERVATION`,
  `_CPU_RESERVATION`, defaults listed in `.env.example`). Set any of
  them in `.env` and the override survives every `git pull`. The
  defaults are what CI boots the stack under, so they are known to be
  enough for a fresh install; raise a limit if a service is OOM-killed
  under your real load (`docker inspect` shows `OOMKilled=true`).

## [1.1.0] - 2026-09-02

### Added

- **`update.sh`** — unattended updates to the newest tagged release,
  and nothing else: a tag is cut only after CI has booted the pinned
  images and passed the smoke tests, so "update to the latest tag" means
  "update to a combination a machine has already run". It refuses to
  cross a major version on its own (`--allow-major` after reading the
  notes), refuses a checkout with local modifications, and supports
  `--dry-run`. Put it on a cron timer for hands-off minor/patch updates.

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

[Unreleased]: https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/compare/v1.3.0...HEAD
[1.3.0]: https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/releases/tag/v1.0.0
