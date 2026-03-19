#!/bin/bash
set -euo pipefail

# Cloud-init user-data script
# Ensures the data volume is formatted, mounted at /data, and persisted via fstab.

DATA_DIR="/data"
DEVICE=""

# Detect the data volume device
# AWS EBS: /dev/xvdf or /dev/nvme1n1
# DigitalOcean: /dev/disk/by-id/scsi-0DO_Volume_*
for dev in /dev/xvdf /dev/nvme1n1; do
  if [ -b "$dev" ]; then
    DEVICE="$dev"
    break
  fi
done

# DigitalOcean volumes appear as /dev/disk/by-id/scsi-0DO_Volume_*
if [ -z "$DEVICE" ]; then
  for dev in /dev/disk/by-id/scsi-0DO_Volume_*; do
    if [ -b "$dev" ]; then
      DEVICE="$dev"
      break
    fi
  done
fi

if [ -z "$DEVICE" ]; then
  echo "No data volume device found, skipping mount"
  mkdir -p "$DATA_DIR"
  exit 0
fi

# Format if no filesystem exists
if ! blkid "$DEVICE" | grep -q TYPE; then
  mkfs.ext4 -L towlion-data "$DEVICE"
fi

# Mount
mkdir -p "$DATA_DIR"
if ! mountpoint -q "$DATA_DIR"; then
  mount "$DEVICE" "$DATA_DIR"
fi

# Persist in fstab
if ! grep -q "$DATA_DIR" /etc/fstab; then
  echo "$DEVICE $DATA_DIR ext4 defaults,nofail 0 2" >> /etc/fstab
fi
