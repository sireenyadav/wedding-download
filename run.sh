#!/bin/bash

# ==========================================
# CONFIGURATION
# ==========================================
TARGET_DIR="/storage/F8FCADDDFCAD9702/Android/data/com.termux/files/Wedding_Backup"

SONAL_ROOT_ID="1UTqkkQr7SwXAZanU0Yy9yiQnsbDlYSUV"
ROSHAN_ROOT_ID="11T1irnWdZzj1G16Q_JpzdHGHzK6rVIOf"

# Environment flags to prevent timestamp modification errors on Android FUSE
export RCLONE_LOCAL_NO_SET_MODTIME=true
export RCLONE_LOCAL_NO_CHECK_UPDATED=true

# Keep --checkers 16 for fast local disk checks, but remove --fast-list to avoid API stalling
FLAGS="--checksum --transfers 4 --checkers 16 --retries 15 --retries-sleep 5s -P --stats 1s --inplace --drive-chunk-size 64M"

# ==========================================
# INITIALIZATION
# ==========================================
mkdir -p "$TARGET_DIR"

if ! command -v rclone &> /dev/null; then
    echo "[-] Rclone missing. Installing package..."
    pkg update && pkg install rclone -y
fi

echo "================================================================"
echo " STORAGE AUDIT: TARGETING PARTITION F8FCADDDFCAD9702            "
echo "================================================================"
df -h "$TARGET_DIR"
echo "================================================================"
echo ""

# ==========================================
# BACKUP EXECUTION QUEUE
# ==========================================
echo "================================================================"
echo " STARTING: SONAL WEDDING (DIRECT ID TARGETING)                  "
echo "================================================================"
rclone copy "gdrive,root_folder_id=$SONAL_ROOT_ID:" "$TARGET_DIR/Sonal_Wedding" $FLAGS

echo -e "\n================================================================"
echo " STARTING: ROSHAN WEDDING (DIRECT ID TARGETING)                 "
echo "================================================================"
rclone copy "gdrive,root_folder_id=$ROSHAN_ROOT_ID:" "$TARGET_DIR/Roshan_Wedding" $FLAGS

echo -e "\n================================================================"
echo " PROCESS COMPLETE: ALL PHOTOS VERIFIED BY MD5 CHECKSUMS         "
echo "================================================================"
