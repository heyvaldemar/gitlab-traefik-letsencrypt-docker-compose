#!/bin/bash
# Host-side GitLab backup: the omnibus image ships `gitlab-backup`, which
# knows the schema, the repositories, the registry and the uploads - a
# generic dump sidecar cannot replace it. This script wraps it for cron:
#
#   17 3 * * *  /opt/gitlab-traefik-letsencrypt-docker-compose/gitlab-backup.sh >> /var/log/gitlab-backup.log 2>&1
#
# Each run produces, under BACKUP_DIR on the host:
#   <timestamp>_gitlab_backup.tar   - everything gitlab-backup covers (repos, DB, uploads, ...)
#   <timestamp>_gitlab_config.tar.gz - /etc/gitlab: gitlab.rb and gitlab-secrets.json, WITHOUT
#                                      which the backup above cannot be decrypted (2FA, CI variables)
# and prunes both kinds older than PRUNE_DAYS. Every step logs OK or FAILED.
#
# Restore: https://docs.gitlab.com/ee/administration/backup_restore/restore_gitlab.html
#   1. same GitLab version as the backup, stack up, then
#      docker compose -p gitlab exec gitlab gitlab-backup restore BACKUP=<timestamp>
#   2. put gitlab-secrets.json back into /etc/gitlab and `gitlab-ctl reconfigure`.

set -euo pipefail
cd "$(dirname "$0")"

PROJECT="${COMPOSE_PROJECT_NAME:-gitlab}"
BACKUP_DIR="${GITLAB_BACKUPS_PATH:-./backups}"
PRUNE_DAYS="${GITLAB_BACKUP_PRUNE_DAYS:-7}"
STAMP="$(date +%Y-%m-%d_%H-%M)"
mkdir -p "$BACKUP_DIR"

log() { echo "[$(date -Iseconds)] $*"; }

# 1. gitlab-backup create (STRATEGY=copy keeps the instance usable while it runs)
if docker compose -p "$PROJECT" exec -T gitlab gitlab-backup create STRATEGY=copy CRON=1 > /dev/null; then
  latest="$(docker compose -p "$PROJECT" exec -T gitlab sh -c 'ls -1t /var/opt/gitlab/backups/*_gitlab_backup.tar | head -1' | tr -d '\r')"
  docker compose -p "$PROJECT" cp "gitlab:${latest}" "$BACKUP_DIR/"
  log "GitLab backup OK: $BACKUP_DIR/$(basename "$latest") ($(stat -c %s "$BACKUP_DIR/$(basename "$latest")" 2>/dev/null || stat -f %z "$BACKUP_DIR/$(basename "$latest")") bytes)"
  # the copy inside the container is now redundant
  docker compose -p "$PROJECT" exec -T gitlab rm -f "$latest"
else
  log "GitLab backup FAILED - gitlab-backup create did not complete; see docker compose -p $PROJECT logs gitlab" >&2
  exit 1
fi

# 2. /etc/gitlab (secrets + configuration)
if docker compose -p "$PROJECT" exec -T gitlab tar -C /etc/gitlab -czf - . > "$BACKUP_DIR/${STAMP}_gitlab_config.tar.gz"; then
  log "Config backup OK: $BACKUP_DIR/${STAMP}_gitlab_config.tar.gz"
else
  log "Config backup FAILED" >&2
  rm -f "$BACKUP_DIR/${STAMP}_gitlab_config.tar.gz"
  exit 1
fi

# 3. prune
if [ "$PRUNE_DAYS" -ge 1 ]; then
  find "$BACKUP_DIR" -type f \( -name '*_gitlab_backup.tar' -o -name '*_gitlab_config.tar.gz' \) -mtime "+$PRUNE_DAYS" -delete
fi
log "backup cycle finished"
