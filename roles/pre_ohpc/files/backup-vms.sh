#!/bin/bash
set -euo pipefail

BACKUP_BASE="/mnt/root-admin/vms-backup"
TMP_DIR="$BACKUP_BASE/.tmp"

LOG_FILE="/var/log/vm-backup.log"
DATE="$(date +%F-%H%M)"

exec >> "$LOG_FILE" 2>&1

echo "===== VM BACKUP START $(date) ====="

fail() {
  echo "[ERROR] $1"
  exit 1
}

mountpoint -q /mnt/root-admin || fail "backup mount not available"

rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

VM_LIST=$(virsh list --name)

for VM in $VM_LIST; do
  echo "[INFO] $VM"

  VM_TMP="$TMP_DIR/$VM"
  mkdir -p "$VM_TMP"

  virsh dumpxml "$VM" > "$VM_TMP/$VM.xml"

  DISK_TARGET=$(virsh domblklist "$VM" --details | awk '$2=="disk"{print $3;exit}')
  DISK_PATH=$(virsh domblklist "$VM" --details | awk '$2=="disk"{print $4;exit}')

  SNAP_PATH="${DISK_PATH}.backup-${DATE}.overlay.qcow2"

  virsh snapshot-create-as \
    --domain "$VM" \
    --name "backup-$DATE" \
    --disk-only \
    --atomic \
    --no-metadata \
    --diskspec "$DISK_TARGET,file=$SNAP_PATH"

  qemu-img convert -p -O qcow2 \
    "$DISK_PATH" \
    "$VM_TMP/$VM.qcow2"

  virsh blockcommit "$VM" "$DISK_TARGET" --active --pivot

  rm -f "$SNAP_PATH"
done

echo "[INFO] Replace old backups"

find "$BACKUP_BASE" -mindepth 1 -maxdepth 1 ! -name ".tmp" -exec rm -rf {} +

mv "$TMP_DIR"/* "$BACKUP_BASE"/

rm -rf "$TMP_DIR"

echo "[OK] VM BACKUP DONE $(date)"