# GitLab + Traefik + Let's Encrypt — Docker Compose

[![Deployment Verification](https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/actions/workflows/deployment-verification.yml/badge.svg?branch=main)](https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/actions/workflows/deployment-verification.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Contents

- [Why this stack?](#why-this-stack)
- [Prerequisites](#prerequisites)
- [Getting started](#getting-started)
- [Features](#features)
  - [Typical use cases](#typical-use-cases)
- [Registering the runner](#registering-the-runner)
- [Email (SMTP)](#email-smtp)
- [Supply chain trust](#supply-chain-trust)
- [Production checklist](#production-checklist)
- [Upgrading an existing deployment](#upgrading-an-existing-deployment)
- [Testing](#testing)
- [Security Notes](#security-notes)
- [About the maintainer](#about-the-maintainer)

This repository deploys **GitLab EE** (free tier) behind **Traefik** with automatic **Let's Encrypt TLS**, backed by an external **PostgreSQL 17**, with git-over-SSH routed through a dedicated Traefik TCP entrypoint and a **GitLab Runner** container ready to register. One `docker compose up` away from a complete DevOps platform at `https://your-domain`.

📙 Full narrative installation guide on the blog: [heyvaldemar.com/install-gitlab-using-docker-compose/](https://www.heyvaldemar.com/install-gitlab-using-docker-compose/).

## Why this stack?

| Need | This stack | Manual omnibus install | Kubernetes (Helm) | Other compose examples |
|------|-----------|------------------------|-------------------|------------------------|
| Ready to deploy in <15 min | ✅ | ❌ | ✅ if K8s is already running | Often |
| TLS via Let's Encrypt, auto-renewed | ✅ Traefik ACME built-in | Manual | Via cert-manager | Rare |
| External PostgreSQL (not the bundled one) | ✅ swappable, backupable | Bundled | ✅ | Rare |
| Git-over-SSH through the proxy | ✅ Traefik TCP entrypoint | Host port 22 juggling | Service/LB config | Rare |
| Runner container included | ✅ | Separate install | ✅ | Varies |
| Upstream images pinned by `sha256` digest | ✅ | N/A | Depends | Rare |
| Weekly pin-freshness check in CI | ✅ | N/A | Depends | Rare |
| CI-verified deployment on every push | ✅ boots + migrates + serves | N/A | Varies | Almost never (too heavy) |
| Credentials via env (never committed) | ✅ | N/A | K8s Secrets | Often committed plaintext |

Four moving parts (Traefik + GitLab + Postgres + runner). Heavy by nature — GitLab is a platform — but with no Kubernetes prerequisites and no manual certificate management.

## Prerequisites

Before you start, you need:

- **A Linux server** with a public IP and **at least 4 GB RAM + 4 CPU cores** (GitLab's own minimum; 8 GB is comfortable). Tested on Ubuntu 22.04 LTS+ and Debian 12+.
- **Docker Engine 24+ and Docker Compose 2.20+.**
- **A domain you control,** with two `A` records pointing at your server's public IP — one for GitLab (e.g. `gitlab.example.com`), one for the Traefik dashboard. DNS must propagate before deploy.
- **Ports 80, 443, and 2222 open** — 2222 carries git-over-SSH (configurable via `GITLAB_SHELL_SSH_PORT`).
- **Disk sized for repositories, artifacts, and the database** — 20 GB is a floor, not a recommendation.

## Getting started

```bash
# 1. Clone
git clone https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose
cd gitlab-traefik-letsencrypt-docker-compose

# 2. Create the two Docker networks the stack expects
docker network create traefik-network
docker network create gitlab-network

# 3. Copy the environment template and fill in required values
cp .env.example .env
$EDITOR .env
# ^ Required: GITLAB_DB_PASSWORD, GITLAB_HOSTNAME, GITLAB_URL,
#   TRAEFIK_HOSTNAME, TRAEFIK_ACME_EMAIL, TRAEFIK_BASIC_AUTH.

# 4. Deploy
docker compose -f gitlab-traefik-letsencrypt-docker-compose.yml -p gitlab up -d
```

First boot runs GitLab's full reconfigure and database migrations — expect **5–10 minutes** before `https://${GITLAB_HOSTNAME}` serves the sign-in page. Then read the generated root password (valid 24 hours — change it right away):

```bash
docker compose -p gitlab exec gitlab cat /etc/gitlab/initial_root_password
```

### What success looks like

```bash
# GitLab turns healthy after migrations complete:
docker compose -f gitlab-traefik-letsencrypt-docker-compose.yml -p gitlab ps

# Sign-in page answers:
curl -fsSL -o /dev/null -w "%{http_code}\n" "https://${GITLAB_HOSTNAME}/users/sign_in"
# Expected: 200

# Readiness probe:
curl -fsS "https://${GITLAB_HOSTNAME}/-/readiness?all=1"

# Traefik issued a certificate:
docker compose -p gitlab logs traefik | grep -i "adding certificate"
```

### Common first-deploy issues

- **502 for the first minutes.** Normal — GitLab is still migrating. Watch `docker compose -p gitlab logs -f gitlab` until `gitlab Reconfigured!`.
- **Cert issuance fails.** DNS hasn't propagated or port 80 isn't reachable from the internet.
- **`docker compose up` fails with `set in .env`.** A required variable is empty; the error names it.
- **`network gitlab-network not found`.** Step 2 was skipped.
- **SSH clone hangs.** Port 2222 closed, or the remote URL uses port 22 — clone URLs are `ssh://git@gitlab.example.com:2222/group/repo.git`.

### Apply `.env` or compose-file changes

```bash
docker compose -f gitlab-traefik-letsencrypt-docker-compose.yml -p gitlab up -d --force-recreate
```

## Features

- **GitLab EE 19.3** (free tier features without a license) — repositories, CI/CD, registry-ready, issues, merge requests.
- **External PostgreSQL 17** with healthcheck — backupable and upgradable independently of the omnibus bundle (`postgresql['enable'] = false`).
- **Traefik v3** with automatic HTTP→HTTPS redirect and Let's Encrypt TLS-ALPN certificate issuance.
- **Git-over-SSH via a dedicated Traefik TCP entrypoint** on port 2222.
- **GitLab Runner container** on the same network, one `register` command away from running your pipelines.
- **SMTP off by default** — opt in via `GITLAB_SMTP_ENABLED` and the `GITLAB_SMTP_*` variables.
- **Credentials required at deploy time** — compose fails fast if `.env` is incomplete.

### Typical use cases

- **Self-hosted DevOps platform** — code, CI/CD, and packages behind your own firewall.
- **Compliance-bound source control** — data residency without SaaS.
- **CI lab** — full pipeline experimentation with a local runner, no minute quotas.
- **Migration staging** — validate a self-managed setup before committing hardware.

## Registering the runner

The `gitlab-runner-1` container ships unregistered. After first login, create a runner in the GitLab UI (Admin → CI/CD → Runners → New instance runner), copy the token, then:

```bash
docker compose -p gitlab exec gitlab-runner-1 gitlab-runner register \
  --url "https://gitlab.example.com" \
  --token "<runner-token>" \
  --executor docker \
  --docker-image alpine:latest
```

## Email (SMTP)

SMTP is **disabled by default**. To enable outgoing email, set `GITLAB_SMTP_ENABLED=true` plus the `GITLAB_SMTP_*` values in `.env` (see `.env.example`), then `docker compose up -d --force-recreate`.

## Supply chain trust

This repository is a **deployment template**, not a custom Docker image. It orchestrates four upstream images:

- [`traefik`](https://hub.docker.com/_/traefik) — reverse proxy, Docker Hub official image
- [`gitlab/gitlab-ee`](https://hub.docker.com/r/gitlab/gitlab-ee) — GitLab upstream
- [`gitlab/gitlab-runner`](https://hub.docker.com/r/gitlab/gitlab-runner) — GitLab Runner upstream
- [`postgres`](https://hub.docker.com/_/postgres) — PostgreSQL, Docker Hub official image

All four are pinned to `tag@sha256:<digest>` as interpolation defaults in the compose file's `x-images` block. Compose pulls by digest, not by tag — and `git pull` alone delivers the version combination this repository has tested. Setting an `*_IMAGE_TAG` variable in `.env` overrides the default when you deliberately want a different version.

The daily `check-pin-freshness` CI job re-resolves each pinned tag against its registry and compares the pinned GitLab and Traefik versions against the latest upstream releases — any drift fails the run and notifies the maintainer. CI's **Deployment Verification** workflow runs on every push, pull request, and every day at 06:00 UTC. GitHub Actions are pinned by commit SHA; Dependabot keeps those fresh.

## Production checklist

- [ ] **Change the root password immediately** — the generated one expires in 24 hours.
- [ ] **Strong secrets.** `GITLAB_DB_PASSWORD` at 24+ random characters; regenerate the Traefik dashboard BCrypt hash per deployment.
- [ ] **Disable open sign-ups** (Admin → Settings → General → Sign-up restrictions) unless you mean it.
- [ ] **Put `gitlab-backup.sh` on a timer** (see Backups) and replicate `GITLAB_BACKUPS_PATH` off-host — the config archive carries `gitlab-secrets.json`, without which a backup is undecryptable.
- [ ] **Verify Let's Encrypt cert issuance** in the Traefik logs on first start.
- [ ] **Size RAM honestly.** GitLab under 4 GB swaps itself to death.
- [ ] **Follow the official upgrade path** for any version move — see below.

## Upgrading an existing deployment

GitLab does **not** support skipping upgrade stops. Moving an existing instance from the previously pinned 17.7 to the current 19.3 requires walking GitLab's documented path (roughly: 17.7 → 17.11 → 18.x stops → 19.x — consult the [upgrade path tool](https://gitlab-com.gitlab.io/support/toolbox/upgrade-path/) for your exact route), **and** migrating the external database from PostgreSQL 14 to 17 (GitLab 18 requires 16+, GitLab 19 requires 17: dump on 14, restore into a fresh 17 volume, at the stop GitLab's docs prescribe).

Practical route: back up everything (`gitlab-backup create`, `/etc/gitlab`, `pg_dump`), then step through the path by setting `GITLAB_IMAGE_TAG` (and `GITLAB_POSTGRES_IMAGE_TAG` at the DB stop) in `.env`, waiting for background migrations to finish at every stop (Admin → Monitoring → Background migrations). Once you reach the pinned versions, remove the overrides from `.env` to switch to repo-managed pins. Fresh deployments need none of this.

## Unattended updates

Releases are the update channel: a tag is cut only after CI has built the pinned images, booted the full stack, and passed the smoke tests. `update.sh` moves a deployment to the newest tag and nothing else:

```bash
./update.sh --dry-run   # show what would be applied
./update.sh             # update within the current major and redeploy
```

Put it on a timer for hands-off minor/patch updates:

```bash
# crontab -e
17 5 * * *  /opt/gitlab-traefik-letsencrypt-docker-compose/update.sh >> /var/log/gitlab-update.log 2>&1
```

The script refuses to cross a MAJOR template version on its own — majors are breaking by definition and their release notes exist to be read. After reading them, `./update.sh --allow-major` performs the jump. It also refuses to touch a checkout with local modifications: your customization belongs in `.env`, which updates never overwrite.

This is deliberately a host-side script and not a container in the stack: an in-stack updater needs the Docker socket (root on the host) and turns "someone pushed to a repo" into "someone deployed to your machine" with no operator in the loop. A cron job under your own user updates only to tagged, CI-verified states and leaves the trust boundary where it was.

## Resource limits

Every service carries memory and CPU limits plus reservations as compose-level defaults — the same values CI boots the stack under. Override any of them in `.env` (the knobs and their defaults are listed in `.env.example`, e.g. `TRAEFIK_MEMORY_LIMIT=512m`) and the override survives every `git pull`. If a service is OOM-killed under real load, `docker inspect <container> --format '{{.State.OOMKilled}}'` says so; raise its `_MEMORY_LIMIT` and recreate.

## Backups

GitLab has its own backup tool that knows the schema, the repositories, the uploads and the registry, so this template wraps it instead of dumping around it. `gitlab-backup.sh` runs `gitlab-backup create STRATEGY=copy` (the instance stays usable), copies the resulting `<timestamp>_gitlab_backup.tar` to `GITLAB_BACKUPS_PATH` (default `./backups`), archives `/etc/gitlab` as `<timestamp>_gitlab_config.tar.gz` — `gitlab-secrets.json` lives there, and without it the backup cannot be decrypted (2FA, CI variables) — and prunes files older than `GITLAB_BACKUP_PRUNE_DAYS` (default 7). Every step logs `OK` or `FAILED`.

```bash
chmod +x gitlab-backup.sh
./gitlab-backup.sh
# cron:
17 3 * * *  /opt/gitlab-traefik-letsencrypt-docker-compose/gitlab-backup.sh >> /var/log/gitlab-backup.log 2>&1
```

**Restore** ([upstream procedure](https://docs.gitlab.com/ee/administration/backup_restore/restore_gitlab.html)): with the same GitLab version running, copy the tar back into the container and run `gitlab-backup restore BACKUP=<timestamp>`, then put `gitlab-secrets.json` from the config archive into `/etc/gitlab` and `gitlab-ctl reconfigure`:

```bash
docker compose -p gitlab cp ./backups/<timestamp>_gitlab_backup.tar gitlab:/var/opt/gitlab/backups/
docker compose -p gitlab exec gitlab gitlab-backup restore BACKUP=<timestamp>
```

**Off-host replication.** `./backups` is on the same host as GitLab — point `GITLAB_BACKUPS_PATH` at a directory your off-host backup solution (restic, rclone, Borg, S3 sync) already covers.

## Container hardening

Every service runs with `security_opt: no-new-privileges:true`, so a process cannot gain privileges through setuid binaries even if it escapes its initial capability set. Infrastructure containers (the reverse proxy, databases, caches, backups) run with `cap_drop: [ALL]` and add back only what their entrypoints need: `NET_BIND_SERVICE` for Traefik to bind :80/:443, `CHOWN`/`SETUID`/`SETGID` (and friends) for database images to own their data directory and drop to their service user. Application containers keep the default capability set on purpose: upstream images assume it, and a wrong guess there is a boot loop in production rather than a hardening win. CI boots the stack under exactly these settings on every push, so what ships is what was tested.

## Testing

The [Deployment Verification](https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/actions/workflows/deployment-verification.yml?query=branch%3Amain) workflow runs on every push, pull request, and every day at 06:00 UTC:

1. **Lint** — actionlint on the workflow.
2. **Trivy scans** of all four pinned images (CRITICAL/HIGH, SARIF to the Security tab).
3. **Pin freshness** (daily/manual) — digest drift plus release-lag checks for GitLab and Traefik.
4. **Deploy-and-test** — boots the full stack with ephemeral credentials, sits through GitLab's first-boot reconfigure and database migrations against the external Postgres 17, and requires the sign-in page to answer 200 through Traefik — the heaviest end-to-end proof in the fleet.

A green run is the authoritative proof that the template deploys end-to-end.

## Security Notes

- Credentials are read from `.env` at deploy time; `.env` is gitignored and compose fails fast on missing required variables.
- **Pre-rotation advisory.** Releases before v1.0.0 (2026-08-31) shipped a tracked `.env` with generated-looking database and SMTP passwords. Rotate them if your deployment reused them.
- The database listens only on the internal network; only 80/443/2222 are exposed through Traefik.
- Upstream image digests are pinned; the daily freshness job flags drift loudly.

---

## About the maintainer

<div align="center">

**Maintained by [Vladimir Mikhalev](https://github.com/heyvaldemar)** — Docker Captain · IBM Champion · AWS Community Builder

[YouTube](https://www.youtube.com/channel/UCf85kQ0u1sYTTTyKVpxrlyQ?sub_confirmation=1) · [Blog](https://heyvaldemar.com) · [LinkedIn](https://www.linkedin.com/in/heyvaldemar/)

</div>
