#!/bin/bash
# Unattended update to the latest RELEASED state of this template.
#
# Design, in one paragraph: releases are the update channel. A tag is cut
# only after CI has built the pinned images, booted the full stack, and
# passed the smoke tests — so "update to the
# newest tag" means "update to a combination a machine has already run",
# which is the guarantee a floating `latest` can never give. The script
# refuses to cross a MAJOR template version on its own: majors are
# breaking by definition (an application platform jump, a changed variable
# contract) and their release notes exist to be read by a person. Nor does
# it skip one of GitLab's required upgrade stops (see below).
#
# Run it from cron or a systemd timer for unattended minor/patch updates:
#   17 5 * * *  /opt/gitlab-traefik-letsencrypt-docker-compose/update.sh >> /var/log/gitlab-update.log 2>&1
#
# Flags:
#   --dry-run      show what would happen, change nothing
#   --allow-major  permit crossing a major version (you read the notes)
#
# Exit codes: 3 a major version, 4 a required variable not set, 5 a GitLab
# required upgrade stop; nothing has moved in any of the three.

set -euo pipefail
cd "$(dirname "$0")"

COMPOSE_FILE="gitlab-traefik-letsencrypt-docker-compose.yml"
PROJECT="${COMPOSE_PROJECT_NAME:-gitlab}"
DRY_RUN=false
ALLOW_MAJOR=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --allow-major) ALLOW_MAJOR=true ;;
    *) echo "unknown flag: $arg" >&2; exit 2 ;;
  esac
done

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "local changes present — commit or stash them first, nothing updated" >&2
  exit 1
fi

# docker compose reads .env last, after the checkout. A .env this user
# cannot read (a copy restored without -p comes back root:root 0600) would
# stop it there, with the tree already on the new tag, and would make every
# required variable below read as "not set". Name the file and stop first.
if [ -e .env ] && [ ! -r .env ]; then
  echo ".env is not readable by $(id -un) ($(stat -c '%A %U:%G' .env 2>/dev/null || stat -f '%Sp %Su:%Sg' .env)) — fix its ownership, nothing updated" >&2
  exit 1
fi

git fetch --tags --quiet origin

latest="$(git tag -l 'v*' --sort=-v:refname | head -1)"
if [ -z "$latest" ]; then
  echo "no release tags found — nothing to update to" >&2
  exit 1
fi

current="$(git describe --tags --abbrev=0 2>/dev/null || echo 'v0.0.0')"
if [ "$(git rev-parse HEAD)" = "$(git rev-parse "$latest^{commit}")" ]; then
  echo "already on $latest"
  exit 0
fi

cur_major="${current#v}"; cur_major="${cur_major%%.*}"
new_major="${latest#v}";  new_major="${new_major%%.*}"
if [ "$new_major" != "$cur_major" ] && [ "$ALLOW_MAJOR" != "true" ]; then
  echo "refusing to cross a major version unattended: $current -> $latest" >&2
  echo "read the release notes, then re-run with --allow-major:" >&2
  echo "  https://github.com/heyvaldemar/gitlab-traefik-letsencrypt-docker-compose/releases/tag/$latest" >&2
  exit 3
fi

# GITLAB'S REQUIRED UPGRADE STOPS. GitLab has to stop at certain minor
# versions, 19.2, 19.5, 19.8 and 19.11 in GitLab 19, and run their
# background migrations to the end before it moves past them. An image
# past a stop refuses to start on data older than it ("It is required to
# upgrade to the latest 19.5.x version first"), which would leave the tree
# on the new tag and GitLab down. The pinned default GitLab of each release
# is compared; a GitLab version set in .env is yours to walk, and is not.
# https://docs.gitlab.com/update/upgrade_paths/
GITLAB_STOPS="19.2 19.5 19.8 19.11"
gitlab_line() {  # TAG -> major.minor of the GitLab image that release pins
  git show "$1:$COMPOSE_FILE" 2>/dev/null \
    | grep -oE 'gitlab/gitlab-ee:\$\{GITLAB_IMAGE_VERSION:-[0-9]+\.[0-9]+' | grep -oE '[0-9]+\.[0-9]+$' | head -1 || true
}
line_num() { echo $(( ${1%%.*} * 1000 + ${1#*.} )); }
cur_gl="$(gitlab_line HEAD)"; new_gl="$(gitlab_line "$latest")"
if [ -n "$cur_gl" ] && [ -n "$new_gl" ] && ! grep -qE '^GITLAB_IMAGE_(TAG|VERSION)=.' .env 2>/dev/null; then
  for stop in $GITLAB_STOPS; do
    if [ "$(line_num "$cur_gl")" -lt "$(line_num "$stop")" ] && [ "$(line_num "$new_gl")" -gt "$(line_num "$stop")" ]; then
      stop_tag=""
      for t in $(git tag -l 'v*' --sort=-v:refname); do
        if [ "$(gitlab_line "$t")" = "$stop" ]; then stop_tag="$t"; break; fi
      done
      echo "refusing to skip GitLab's required upgrade stop $stop: $current runs GitLab $cur_gl, $latest runs GitLab $new_gl" >&2
      if [ -n "$stop_tag" ]; then
        echo "update to $stop_tag (GitLab $stop) first, nothing else changes:" >&2
        echo "  git checkout -q $stop_tag && docker compose -f $COMPOSE_FILE -p $PROJECT up -d --remove-orphans" >&2
        echo "then wait until Admin > Monitoring > Background migrations has nothing queued or running, and run this again" >&2
      else
        echo "no release of this template pins GitLab $stop: see https://docs.gitlab.com/update/upgrade_paths/" >&2
      fi
      exit 5
    fi
  done
fi

# NEW VARIABLES SINCE YOUR VERSION. An update can add a required variable,
# and `docker compose up` would then stop with a message naming it - after
# the checkout, with the tree already on the new tag. Better to say so here,
# before anything has moved. Names only, never values.
if [ -n "${COMPOSE_FILES+x}" ]; then _files=("${COMPOSE_FILES[@]}"); else _files=("$COMPOSE_FILE"); fi
_new="$(comm -13 <(git show "HEAD:.env.example" 2>/dev/null | grep -oE '^[A-Z0-9_]+=' | tr -d '=' | sort -u) \
               <(git show "$latest:.env.example" 2>/dev/null | grep -oE '^[A-Z0-9_]+=' | tr -d '=' | sort -u))"
if [ -n "$_new" ]; then
  echo "new variables in .env.example since $current:"
  while IFS= read -r _k; do echo "  $_k"; done <<<"$_new"
  _required=""
  for _f in "${_files[@]}"; do
    _required="$_required $(git show "$latest:$_f" 2>/dev/null | grep -oE '\$\{[A-Z0-9_]+:\?' | sed -E 's/^\$\{//; s/:\?$//' | tr '\n' ' ' || true)"
  done
  _missing=""
  for _k in $_new; do
    case " $_required " in *" $_k "*) grep -qE "^${_k}=." .env 2>/dev/null || _missing="$_missing $_k" ;; esac
  done
  if [ -n "$_missing" ]; then
    echo "required in $latest and not set in .env:$_missing" >&2
    echo "see .env.example at $latest for what each one is; nothing was changed" >&2
    [ "$DRY_RUN" = "true" ] || exit 4
  fi
fi

echo "updating $current -> $latest"
if [ "$DRY_RUN" = "true" ]; then
  git log --oneline "HEAD..$latest^{commit}" | sed 's/^/  would apply: /'
  echo "dry run — nothing changed"
  exit 0
fi

git checkout -q "$latest"
docker compose -f "$COMPOSE_FILE" -p "$PROJECT" up -d --remove-orphans
echo "now on $latest"
