# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

_(no unreleased changes yet)_

## [1.8.0] - 2026-09-26

### Added

- **Traefik's timeouts on the HTTPS entry point can be set from `.env`.**
  `TRAEFIK_READ_TIMEOUT`, `TRAEFIK_WRITE_TIMEOUT` and `TRAEFIK_IDLE_TIMEOUT`
  default to Traefik's own values (60s, 0s, 180s), so nothing changes unless
  you set them. Traefik reads its static configuration from one source, here
  the command in the compose file, and an override file can only replace that
  command whole; a variable is the way to tune it and keep taking updates.
  The same change was asked for in the [Keycloak template](https://github.com/heyvaldemar/keycloak-traefik-letsencrypt-docker-compose), and every template in the fleet gets it at once.

## [1.7.5] - 2026-09-25

### Security

- **`postgres:17` was rebuilt upstream**; the pin moved from `sha256:f4c66b820c6f…` to `sha256:d74eeac9a635…`. Same version, same tag, a rebuilt base image — the usual shape of a security fix in a base layer.

## [1.7.4] - 2026-09-23

### Changed

- **The freshness check has its own workflow, Pin Freshness.** It ran inside Deployment Verification, whose badge is the one at the top of this README. Across the fleet, nine red runs in ten were a pin one version behind - which the fleet's triage moves within the day - and a reader cannot tell that from a stack that does not boot. The badge now says whether the stack boots. The job itself is unchanged.
- **`gitlab/gitlab-ee:19.4.0-ee.0` moved to `19.4.1-ee.0`.** GitLab publishes no
  release notes for a patch in this line, and the commit list is largely
  "Add latest changes from gitlab-org/security/gitlab@19-4-stable-ee" — security
  backports, which are disclosed later and by design carry no detail now. That
  is a reason to move, not to wait.

  Asked of the registry, the two images are identical in every field that
  changes behaviour: user, entrypoint, command, working directory, ports,
  volumes, healthcheck and the whole environment. Nothing in the contract
  between the container and this compose file moved.

- **`gitlab/gitlab-runner` stays at `ubuntu-v19.4.0`.** The `ubuntu-v19.4.1` tag
  is announced but not published — the registry answers 404 for it. The runner
  is supported against a server of the same or newer minor, so 19.4.0 against
  19.4.1 is a supported pair, and the freshness check stays red until upstream
  pushes the tag. That red is upstream's to clear, not this repository's.

### Changed

- **`gitlab/gitlab-ee:19.4.0-ee.0` moved to `gitlab/gitlab-ee:19.4.1-ee.0`.** The freshness check reported the lag; the deploy job booted the stack on the new image before this landed.

## [1.7.3] - 2026-09-21

### Security

- **`traefik:3.7` was rebuilt upstream**; the pin moved from `sha256:1c32e7c36820…` to `sha256:24841fe2de73…`. Same version, same tag, a rebuilt base image — the usual shape of a security fix in a base layer.

## [1.7.2] - 2026-09-19

### Security

- **`postgres:17` was rebuilt upstream**; the pin moved from `sha256:67f41722b7a8…` to `sha256:f4c66b820c6f…`. Same version, same tag, a rebuilt base image — the usual shape of a security fix in a base layer.

## [1.7.1] - 2026-09-18

### Security

- **`traefik:3.7` was rebuilt upstream**; the pin moved from `sha256:f86a2cab1b5c…` to `sha256:1c32e7c36820…`. Same version, same tag, a rebuilt base image — the usual shape of a security fix in a base layer.

## [1.7.0] - 2026-09-18

### Changed

- **GitLab 19.4.** The runner moved to 19.4.0 first, on its own, which left it
  a minor ahead of the server it is meant to track. This moves the server to
  match, and the two are pinned in lockstep again.

  **First boot runs GitLab's database migrations, and they are not reversible.**
  That is the whole of the disruption, and it is why this is a minor here and
  not a patch. Take the backup this template's own `gitlab-backup.sh` produces
  before pulling it on a live deployment.

  What was checked rather than assumed: GitLab's required upgrade stops for 19
  are 19.2, 19.5, 19.8 and 19.11, so 19.3 to 19.4 is a direct hop with no
  intermediate stop. GitLab 19.x requires PostgreSQL 17, minimum and maximum,
  and this template pins `postgres:17`. The upstream review could not read
  release notes for the range, because GitLab does not publish them to GitHub,
  and said so rather than guessing; the deploy job brought the previous release
  up first on the volumes this one upgrades, ran the migrations, answered
  through Traefik and produced a backup before this landed.

### Changed

- **`gitlab/gitlab-runner:ubuntu-v19.3.2` moved to `gitlab/gitlab-runner:ubuntu-v19.4.0`.** The freshness check reported the lag; the deploy job booted the stack on the new image before this landed.

## [1.6.7] - 2026-09-13

### Fixed

- **v1.6.6 announced GitLab 19.3.2 and shipped 19.3.1.** Its commit touched
  `CHANGELOG.md` and nothing else. Fleet triage builds the substitution from the
  version the freshness check reports, which is `19.3.1`, while the image tag is
  `19.3.1-ee.0`, so it matched nothing. The lines after that loop ran anyway:
  the report claimed a bump, the changelog announced one, the CI gate passed
  because nothing had changed, and the release went out.

  This release actually moves the pin to `19.3.2-ee.0`, and triage will no
  longer write a changelog entry or cut a release for a bump that edited no
  file. Nobody who upgraded to v1.6.6 got a different GitLab than v1.6.5; they
  get 19.3.2 here.

## [1.6.6] - 2026-09-13

### Changed

- **`gitlab/gitlab-ee:19.3.1-ee.0` moved to `gitlab/gitlab-ee:19.3.2-ee.0`.** The freshness check reported the lag; the deploy job booted the stack on the new image before this landed.

## [1.6.5] - 2026-09-12

### Changed

- **`gitlab/gitlab-ee:19.3.1-ee.0` moved to `gitlab/gitlab-ee:19.3.2-ee.0`.** The freshness check reported the lag; the deploy job booted the stack on the new image before this landed.

## [1.6.4] - 2026-09-12

### Changed

- **`gitlab/gitlab-ee:19.3.1-ee.0` moved to `gitlab/gitlab-ee:19.3.2-ee.0`.** The freshness check reported the lag; the deploy job booted the stack on the new image before this landed.

## [1.6.3] - 2026-09-11

### Changed

- **`gitlab/gitlab-ee:19.3.1-ee.0` moved to `gitlab/gitlab-ee:19.3.2-ee.0`.** The freshness check reported the lag; the deploy job booted the stack on the new image before this landed.

## [1.6.2] - 2026-09-11

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

[Unreleased]: https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/compare/v1.8.0...HEAD
[1.8.0]: https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/compare/v1.7.5...v1.8.0
[1.7.5]: https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/compare/v1.7.4...v1.7.5
[1.7.4]: https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/compare/v1.7.3...v1.7.4
[1.7.3]: https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/compare/v1.7.2...v1.7.3
[1.7.2]: https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/compare/v1.7.1...v1.7.2
[1.7.1]: https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/compare/v1.7.0...v1.7.1
[1.7.0]: https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/compare/v1.6.7...v1.7.0
[1.6.7]: https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/releases/tag/v1.6.7
[1.6.6]: https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/compare/v1.6.5...v1.6.6
[1.6.5]: https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/compare/v1.6.4...v1.6.5
[1.6.4]: https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/compare/v1.6.3...v1.6.4
[1.6.3]: https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/compare/v1.6.2...v1.6.3
[1.6.2]: https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/compare/v1.6.1...v1.6.2
[1.6.1]: https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/compare/v1.6.0...v1.6.1
[1.6.0]: https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/compare/v1.5.0...v1.6.0
[1.5.0]: https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/compare/v1.4.0...v1.5.0
[1.4.0]: https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/releases/tag/v1.0.0
