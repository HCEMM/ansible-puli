#!/usr/bin/env bash
set -euo pipefail

LOG_TAG="${LOG_TAG:-loginnode-2fa-enforce}"
GRACE_SECONDS="${GRACE_SECONDS:-3600}"
EXCLUDE_USERS_REGEX="${EXCLUDE_USERS_REGEX:-^(root|admin|guacadmin)$}"
TEST_ONLY_USER="${TEST_ONLY_USER:-}"

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing command: $1" >&2
    exit 1
  }
}

log() {
  local msg="$*"
  logger -t "$LOG_TAG" "$msg"
  echo "[$(date '+%F %T')] $msg"
}

user_has_otp_token() {
  local user="$1"
  local count

  count="$(
    ipa otptoken-find --owner="$user" 2>/dev/null \
      | awk '/Number of entries returned/ {print $NF; found=1} END {if (!found) print 0}'
  )"

  [[ "${count:-0}" =~ ^[0-9]+$ ]] && [[ "${count:-0}" -gt 0 ]]
}

notify_user_sessions() {
  local user="$1"
  local message="$2"

  while read -r _ tty _ _; do
    [[ -n "${tty:-}" && "${tty:-}" != "-" ]] || continue
    echo "$message" | write "$user" "$tty" 2>/dev/null || true
  done < <(who | awk -v u="$user" '$1==u')
}

terminate_user() {
  local user="$1"
  loginctl kill-user "$user" 2>/dev/null || true
}

main() {
  need loginctl
  need ipa
  need awk
  need logger
  need who
  need write
  need date
  need klist

  if ! klist -s; then
    log "No Kerberos ticket found. Aborting."
    exit 1
  fi

  local now
  now="$(date +%s)"

  while read -r session_id _; do
    [[ -n "${session_id:-}" ]] || continue

    local user uid state ts start_epoch age

    user="$(loginctl show-session "$session_id" -p Name --value 2>/dev/null || true)"
    uid="$(loginctl show-session "$session_id" -p User --value 2>/dev/null || true)"
    state="$(loginctl show-session "$session_id" -p State --value 2>/dev/null || true)"
    ts="$(loginctl show-session "$session_id" -p Timestamp --value 2>/dev/null || true)"

    [[ -n "${user:-}" ]] || continue
    [[ "$user" =~ $EXCLUDE_USERS_REGEX ]] && continue
    [[ "${uid:-}" =~ ^[0-9]+$ ]] || continue
    (( uid >= 1000 )) || continue
    [[ "${state:-}" == "active" ]] || continue

    if [[ -n "${TEST_ONLY_USER}" && "$user" != "$TEST_ONLY_USER" ]]; then
      continue
    fi

    start_epoch="$(date -d "$ts" +%s 2>/dev/null || true)"
    [[ "${start_epoch:-}" =~ ^[0-9]+$ ]] || continue

    age=$(( now - start_epoch ))
    (( age >= GRACE_SECONDS )) || continue

    if user_has_otp_token "$user"; then
      log "[$user] session ${session_id} older than grace period, OTP exists; skipping"
      continue
    fi

    log "[$user] session ${session_id} has no OTP after ${age}s; notifying and terminating"

    notify_user_sessions "$user" "You did not configure 2FA within the allowed time. Your session is being terminated now. Please log in again and run: 2fa-setup"
    sleep 5
    terminate_user "$user"
  done < <(loginctl list-sessions --no-legend 2>/dev/null)

  log "Login-node 2FA enforcement completed"
}

main "$@"