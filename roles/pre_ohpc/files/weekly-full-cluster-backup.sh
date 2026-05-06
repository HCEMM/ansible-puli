#!/bin/bash
set -euo pipefail

LOG_FILE="/var/log/weekly-full-cluster-backup.log"

BACKUP_MOUNT="/mnt/root-admin"

REAR_BASE="$BACKUP_MOUNT/rear-backup"
REAR_TMP="$REAR_BASE/.tmp"

REAR_RUNTIME_DIR="/etc/rear-weekly"
REAR_RUNTIME_CONF="$REAR_RUNTIME_DIR/local.conf"

REAR_ORIGINAL_CONF="/etc/rear/local.conf"

HOSTNAME_SHORT="$(hostname -s)"

exec >> "$LOG_FILE" 2>&1

echo "===================================================="
echo "===== FULL BACKUP START $(date) ====="

fail() {
  echo "[ERROR] $1"
  echo "[ERROR] Weekly backup failed at $(date)"
  exit 1
}

cleanup() {
  rm -rf "$REAR_RUNTIME_DIR" || true
}
trap cleanup EXIT

mountpoint -q "$BACKUP_MOUNT" || fail "$BACKUP_MOUNT is not mounted."

echo "[INFO] Backup mount OK"

echo "[INFO] Step 1/2: VM backup"
/root/backup-vms.sh || fail "VM backup failed"

echo "[OK] VM backup done"

echo "[INFO] Step 2/2: ReaR backup"

rm -rf "$REAR_TMP"
mkdir -p "$REAR_TMP"

rm -rf "$REAR_RUNTIME_DIR"
mkdir -p "$REAR_RUNTIME_DIR"

cp "$REAR_ORIGINAL_CONF" "$REAR_RUNTIME_CONF"

sed -i '/^BACKUP_URL=/d' "$REAR_RUNTIME_CONF"

echo "BACKUP_URL=file://$REAR_TMP" >> "$REAR_RUNTIME_CONF"

rm -rf /var/tmp/rear.*

env PATH=/usr/sbin:/usr/bin:/sbin:/bin \
rear -v -c "$REAR_RUNTIME_DIR" mkbackup || fail "ReaR failed"

REAR_OUTPUT="$REAR_TMP/$HOSTNAME_SHORT"

[ -d "$REAR_OUTPUT" ] || fail "Missing ReaR output directory"
[ -s "$REAR_OUTPUT/backup.tar.gz" ] || fail "missing backup.tar.gz"
[ -s "$REAR_OUTPUT/rear-$HOSTNAME_SHORT.iso" ] || fail "missing ISO"

echo "[INFO] Replacing old ReaR backup"

find "$REAR_BASE" -mindepth 1 -maxdepth 1 ! -name ".tmp" -exec rm -rf {} +

mv "$REAR_OUTPUT" "$REAR_BASE"/

rm -rf "$REAR_TMP"

echo "[OK] Weekly full backup completed at $(date)"
echo "===================================================="