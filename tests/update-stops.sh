#!/usr/bin/env bash
# update.sh and GitLab's required upgrade stops, run for real in a sandbox:
# an origin whose releases pin GitLab versions on both sides of a stop, a
# clone on one of them, `update.sh --dry-run`. No network, no Docker.
#
# GitLab refuses to start past a stop on data older than it, so an update
# that skips one leaves the tree on the new tag and GitLab down. update.sh
# must refuse first (exit 5) and name the release to stop at.
#
# Each case runs twice: on update.sh as it is, and with the stop check taken
# out, because a test that passes without the thing it tests proves nothing.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

pass=0; fail=0
ok() { pass=$((pass + 1)); printf '  ok    %s\n' "$1"; }
no() { fail=$((fail + 1)); printf '  FAIL  %s\n' "$1"; }

COMPOSE_FILE="gitlab-traefik-letsencrypt-docker-compose.yml"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT

# The script under test, and the same script with the stop check cut out.
cp update.sh "$WORK/update.sh"
awk '/^# GITLAB.S REQUIRED UPGRADE STOPS/ { skip = 1 } /^# NEW VARIABLES SINCE YOUR VERSION/ { skip = 0 } !skip' \
  update.sh >"$WORK/update.nostops.sh"
if cmp -s "$WORK/update.sh" "$WORK/update.nostops.sh"; then
  echo "could not cut the stop check out of update.sh; the markers moved" >&2
  exit 1
fi

g() { git -c user.name=t -c user.email=t@example.invalid -c init.defaultBranch=main "$@"; }

# sandbox <update.sh> <host tag> <env line or ""> <tag=gitlab version>...
# Prints "<rc> <same|moved>" on the first line, then the script's output.
sandbox() {
  local up="$1" host="$2" envline="$3" d o tv tag ver before rc
  shift 3
  d="$(mktemp -d "$WORK/s.XXXX")"; o="$d/origin"
  g init -q "$o"
  cp "$up" "$o/update.sh"; chmod +x "$o/update.sh"
  printf 'GITLAB_HOSTNAME=gitlab.example.com\n' >"$o/.env.example"
  printf '.env\n' >"$o/.gitignore"
  for tv in "$@"; do
    tag="${tv%%=*}"; ver="${tv#*=}"
    # shellcheck disable=SC2016 # the compose file's own ${...}, written as is
    printf 'x-images:\n  gitlab: &gitlab-image ${GITLAB_IMAGE_TAG:-gitlab/gitlab-ee:${GITLAB_IMAGE_VERSION:-%s-ee.0@sha256:%064d}}\n' "$ver" 0 >"$o/$COMPOSE_FILE"
    g -C "$o" add -A >/dev/null && g -C "$o" commit -q -m "$tag" && g -C "$o" tag "$tag"
  done
  g clone -q "$o" "$d/host" 2>/dev/null
  g -C "$d/host" checkout -q "$host"
  [ -z "$envline" ] || printf '%s\n' "$envline" >"$d/host/.env"
  before="$(g -C "$d/host" rev-parse HEAD)"
  rc=0; out="$(cd "$d/host" && ./update.sh --dry-run 2>&1)" || rc=$?
  if [ "$(g -C "$d/host" rev-parse HEAD)" = "$before" ]; then echo "$rc same"; else echo "$rc moved"; fi
  printf '%s\n' "$out"
}

# expect <name> <rc> <text or ""> <sandbox args...>: the script as it is
# must give <rc> and <text>; without the stop check it must not give 5.
expect() {
  local name="$1" want="$2" text="$3" res first line
  shift 3
  res="$(sandbox "$WORK/update.sh" "$@")"; first="${res%%$'\n'*}"
  if [ "$first" = "$want same" ] && { [ -z "$text" ] || grep -qF -- "$text" <<<"$res"; }; then
    ok "$name: exit ${first%% *}, tree unchanged${text:+, says \"$text\"}"
  else
    no "$name: wanted exit $want with the tree unchanged${text:+ and \"$text\"}, got:"
    while IFS= read -r line; do printf '        %s\n' "$line"; done <<<"$res"
  fi
  if [ "$want" = 5 ]; then
    res="$(sandbox "$WORK/update.nostops.sh" "$@")"; first="${res%%$'\n'*}"
    if [ "${first%% *}" != 5 ]; then
      ok "$name, stop check taken out: exit ${first%% *} (the check is what refuses)"
    else
      no "$name, stop check taken out: still exit 5, so something else refuses"
    fi
  fi
}

echo "=== update.sh and GitLab's required upgrade stops ==="
expect "19.4 -> 19.6 over the 19.5 stop" 5 "update to v1.1.0 (GitLab 19.5) first" \
  v1.0.0 "" v1.0.0=19.4.2 v1.1.0=19.5.8 v1.2.0=19.6.1
expect "19.5 -> 19.6, from the stop itself" 0 "dry run" \
  v1.1.0 "" v1.0.0=19.4.2 v1.1.0=19.5.8 v1.2.0=19.6.1
expect "19.4 -> 19.5, onto the stop" 0 "dry run" \
  v1.0.0 "" v1.0.0=19.4.2 v1.1.0=19.5.8
expect "19.4 -> 19.6 with no release on 19.5" 5 "no release of this template pins GitLab 19.5" \
  v1.0.0 "" v1.0.0=19.4.2 v1.2.0=19.6.1
expect "19.1 -> 19.6 over two stops names the first" 5 "update to v1.1.0 (GitLab 19.2) first" \
  v1.0.0 "" v1.0.0=19.1.3 v1.1.0=19.2.9 v1.2.0=19.5.8 v1.3.0=19.6.1
expect "GitLab version set in .env is left to its owner" 0 "dry run" \
  v1.0.0 "GITLAB_IMAGE_VERSION=19.4.2-ee.0" v1.0.0=19.4.2 v1.1.0=19.5.8 v1.2.0=19.6.1
expect "19.8 -> 19.9 over nothing" 0 "dry run" \
  v1.0.0 "" v1.0.0=19.8.4 v1.1.0=19.9.0

echo
echo "passed: $pass   failed: $fail"
[ "$fail" = 0 ]
