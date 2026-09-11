# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- **`gitlab/gitlab-runner:ubuntu-v19.3.1` moved to `gitlab/gitlab-runner:ubuntu-v19.3.2`.** The freshness check reported the lag; the deploy job booted the stack on the new image before this landed.
- **`gitlab/gitlab-ee:19.3.1-ee.0` moved to `gitlab/gitlab-ee:19.3.2-ee.0`.** The freshness check reported the lag; the deploy job booted the stack on the new image before this landed.

## [1.6.1] - 2026-09-07

### Changed

- **`update.sh` names any new required variable before it moves.** An update can add a required variable; `docker compose up` used to stop on it after the checkout, with the tree already on the new tag. The script now lists the variables that appeared in `.env.example` since your version and refuses, before anything has moved, when a required one is not in your `.env`. Names only, never values.

aves them
  behind for a person to clear by hand. Sixty seconds now, overridable per
  service with `<PREFIX>_STOP_GRACE_PERIOD` in `.env`. The backup sidecar is
  deliberately left alone: its failure mode is a truncated dump file, which a
  longer grace period does not fix.

## [1.5.0] - 2026-09-03

### Added

- **Per-image version overrides.** Every pin in the `x-images` block is
  now `${<PREFIX>_IMAGE_TAG:-repo:${<PREFIX>_IMAGE_VERSION:-tag@sha256:digest}}`.
  Set `<PREFIX>_IMAGE_VERSION` in `.env` to run a different version of one
  image while every other pin stays as tested (Compose pulls that tag
  without a digest), or `<PREFIX>_IMAGE_TAG` to replace the whole
  reference as before. A deployment that sets neither is unchanged. The
  freshness job, the Trivy matrix and the fleet digest automation resolve
  the nested default before reading a pin. Needs Docker Compose v2.5 or
  newer (2022): v2.0 to v2.4 leave the inner `${...}` unexpanded and
  `docker compose up` fails with an invalid reference instead of
  deploying something unexpected.

## [1.4.0] - 2026-09-02

### Security

- **Container hardening.** Every service runs with
  `security_opt: no-new-privileges:true` (no privilege escalation via
  setuid binaries even if a process escapes its initial capability
  set). Infrastructure containers (the reverse proxy, databases,
  caches, backups) drop every Linux capability and add back only what
  their entrypoints need (bind :80/:443, chown a data directory, drop to
  the service user). Application containers keep the default capability
  set: upstream images assume it, and a wrong guess there is a boot loop
  in production, not a hardening win. CI boots the stack under these
  settings on every push.

## [1.3.0] - 2026-09-02

### Added

- **`gitlab-backup.sh`**: a cron-ready host script around the tool that
  actually knows GitLab: `gitlab-backup create STRATEGY=copy` (repos,
  database, uploads, registry, ...), copied out to `GITLAB_BACKUPS_PATH`
  (default `./backups`), plus a `tar.gz` of `/etc/gitlab`: `gitlab.rb`
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

- **`update.sh`**: unattended updates to the newest tagged release,
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

- **GitLab bumped 17.7.2-ee → 19.3.1-ee** and PostgreSQL 14 → 17
  (GitLab 19.x requires PostgreSQL 17). ❗ Existing deployments cannot jump
  straight to these versions. See the release notes for the mandatory
  GitLab upgrade path and the database migration.
- **Traefik bumped 3.2 → 3.7**: Traefik 3.2's Docker client cannot talk
  to Docker Engine 29 (provider retry loop, silent 404s on current hosts).
- **All four images pinned by `tag@sha256:digest`.**
- **Credentials untracked from git.** The tracked `.env` carried
  generated-looking database and SMTP passwords published on GitHub:
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

[Unreleased]: https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/compare/v1.6.1...HEAD
[1.6.1]: https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/compare/v1.6.0...v1.6.1
[1.6.0]: https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/compare/v1.5.0...v1.6.0
[1.5.0]: https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/compare/v1.4.0...v1.5.0
[1.4.0]: https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/releases/tag/v1.0.0
