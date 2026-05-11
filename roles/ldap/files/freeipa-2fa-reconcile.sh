#!/usr/bin/env bash
set -euo pipefail

LOG_TAG="${LOG_TAG:-freeipa-2fa-reconcile}"
EXCLUDE_USERS_REGEX="${EXCLUDE_USERS_REGEX:-^(admin|root|guacadmin|ipaapi|dirsrv|pkiuser|Monitoring)$}"
DRY_RUN="${DRY_RUN:-false}"
DEBUG_USER="${DEBUG_USER:-}"

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

run_cmd() {
  if [[ "$DRY_RUN" == "true" ]]; then
    log "[DRY-RUN] $*"
    return 0
  else
    "$@"
  fi
}

has_exact_line() {
  local pattern="$1"
  local text="$2"
  grep -Eq "$pattern" <<<"$text"
}

get_all_users() {
  ipa user-find --sizelimit=0 --all --raw 2>/dev/null \
    | awk -F': ' '/^[[:space:]]*uid: / {print $2}' \
    | sort -u
}

get_user_raw() {
  local user="$1"
  ipa user-show "$user" --all --raw 2>/dev/null || true
}

get_token_count() {
  local user="$1"
  local out
  out="$(ipa otptoken-find --owner="$user" 2>&1 || true)"

  if [[ -n "$DEBUG_USER" && "$user" == "$DEBUG_USER" ]]; then
    log "[DEBUG][$user] otptoken-find raw output:"
    while IFS= read -r line; do
      log "[DEBUG][$user] $line"
    done <<< "$out"
  fi

  local count
  count="$(
    echo "$out" | awk '
      /Number of entries returned/ {print $NF; found=1}
      END {if (!found) print "PARSE_ERROR"}
    '
  )"

  echo "$count"
}

ensure_password_plus_otp() {
  local user="$1"
  local raw has_password has_otp

  raw="$(get_user_raw "$user")"
  has_password="false"
  has_otp="false"

  if has_exact_line '^[[:space:]]*ipauserauthtype: password$' "$raw"; then
    has_password="true"
  fi

  if has_exact_line '^[[:space:]]*ipauserauthtype: otp$' "$raw"; then
    has_otp="true"
  fi

  if [[ "$has_password" == "true" && "$has_otp" == "true" ]]; then
    log "[$user] already in desired state: password + otp"
    return 0
  fi

  if [[ "$has_password" == "false" ]]; then
    if run_cmd ipa user-mod "$user" --addattr=ipaUserAuthType=password >/dev/null 2>&1; then
      log "[$user] added ipaUserAuthType=password"
    else
      log "[$user] failed to add ipaUserAuthType=password"
      return 1
    fi
  fi

  if [[ "$has_otp" == "false" ]]; then
    if run_cmd ipa user-mod "$user" --addattr=ipaUserAuthType=otp >/dev/null 2>&1; then
      log "[$user] added ipaUserAuthType=otp"
    else
      log "[$user] failed to add ipaUserAuthType=otp"
      return 1
    fi
  fi

  log "[$user] reconciled to: password + otp"
}

ensure_otp_only() {
  local user="$1"
  local raw has_password has_otp

  raw="$(get_user_raw "$user")"
  has_password="false"
  has_otp="false"

  if [[ -n "$DEBUG_USER" && "$user" == "$DEBUG_USER" ]]; then
    log "[DEBUG][$user] user-show raw output:"
    while IFS= read -r line; do
      log "[DEBUG][$user] $line"
    done <<< "$raw"
  fi

  if has_exact_line '^[[:space:]]*ipauserauthtype: password$' "$raw"; then
    has_password="true"
  fi

  if has_exact_line '^[[:space:]]*ipauserauthtype: otp$' "$raw"; then
    has_otp="true"
  fi

  if [[ -n "$DEBUG_USER" && "$user" == "$DEBUG_USER" ]]; then
    log "[DEBUG][$user] has_password=$has_password has_otp=$has_otp"
  fi

  if [[ "$has_otp" == "true" && "$has_password" == "false" ]]; then
    log "[$user] already in desired state: otp only"
    return 0
  fi

  if [[ "$has_otp" == "false" ]]; then
    if run_cmd ipa user-mod "$user" --addattr=ipaUserAuthType=otp >/dev/null 2>&1; then
      log "[$user] added ipaUserAuthType=otp"
    else
      log "[$user] failed to add ipaUserAuthType=otp"
      return 1
    fi
  fi

  if [[ "$has_password" == "true" ]]; then
    if run_cmd ipa user-mod "$user" --delattr=ipaUserAuthType=password >/dev/null 2>&1; then
      log "[$user] removed ipaUserAuthType=password"
    else
      log "[$user] failed to remove ipaUserAuthType=password"
      return 1
    fi
  fi

  log "[$user] reconciled to: otp only"
}

process_user() {
  local user="$1"
  local token_count

  [[ -z "$user" ]] && return 0

  if [[ "$user" =~ $EXCLUDE_USERS_REGEX ]]; then
    log "[$user] skipped (excluded)"
    return 0
  fi

  token_count="$(get_token_count "$user")"
  token_count="${token_count:-0}"

  if [[ -n "$DEBUG_USER" && "$user" == "$DEBUG_USER" ]]; then
    log "[DEBUG][$user] parsed token_count=$token_count"
  fi

  if [[ "$token_count" == "PARSE_ERROR" ]]; then
    log "[$user] could not parse OTP token count; skipping user"
    return 0
  fi

  if [[ "$token_count" =~ ^[0-9]+$ ]] && [[ "$token_count" -gt 0 ]]; then
    log "[$user] has ${token_count} OTP token(s)"
    ensure_otp_only "$user" || log "[$user] reconcile to otp only failed"
  else
    log "[$user] has no OTP token"
    ensure_password_plus_otp "$user" || log "[$user] reconcile to password + otp failed"
  fi
}

main() {
  need ipa
  need awk
  need grep
  need sort
  need logger
  need klist

  if ! klist -s; then
    log "No Kerberos ticket found. Aborting."
    exit 1
  fi

  mapfile -t USERS < <(get_all_users)

  if [[ ${#USERS[@]} -eq 0 ]]; then
    log "No users returned by ipa user-find"
    exit 1
  fi

  log "Starting reconciliation for ${#USERS[@]} users"

  local user token_count

  for user in "${USERS[@]}"; do
    token_count="$(get_token_count "$user")"
    if [[ "$token_count" =~ ^[0-9]+$ ]] && [[ "$token_count" -gt 0 ]]; then
      process_user "$user"
    fi
  done

  for user in "${USERS[@]}"; do
    token_count="$(get_token_count "$user")"
    if [[ ! "$token_count" =~ ^[0-9]+$ ]] || [[ "$token_count" -eq 0 ]]; then
      process_user "$user"
    fi
  done

  log "Reconciliation completed"
}

main "$@"