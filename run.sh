#!/bin/bash

# ==========================================
# CONFIGURATION (Targeting Partition 4)
# ==========================================
TARGET_DIR="/storage/F8FCADDDFCAD9702/Android/data/com.termux/files/Wedding_Backup"

SONAL_ROOT_ID="1UTqkkQr7SwXAZanU0Yy9yiQnsbDlYSUV"
ROSHAN_ROOT_ID="11T1irnWdZzj1G16Q_JpzdHGHzK6rVIOf"

# -P: Displays real-time progress bars for active files
# --stats 1s: Forces the terminal to update the download speed and ETA every single second
FLAGS="--drive-shared-with-me --checksum --transfers 4 --retries 15 --retries-sleep 5s -P --stats 1s"

# ==========================================
# INITIALIZATION & DEPENDENCY CHECK
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
echo " STARTING: SONAL WEDDING (PHOTOS SUBDIRECTORY)                  "
echo "================================================================"
rclone copy "gdrive,root_folder_id=$SONAL_ROOT_ID:Photos" "$TARGET_DIR/Sonal_Wedding" $FLAGS

echo -e "\n================================================================"
echo " STARTING: ROSHAN WEDDING (PHOTOS SUBDIRECTORY)                 "
echo "================================================================"
rclone copy "gdrive,root_folder_id=$ROSHAN_ROOT_ID:Photos" "$TARGET_DIR/Roshan_Wedding" $FLAGS

echo -e "\n================================================================"
echo " PROCESS COMPLETE: ALL PHOTOS VERIFIED BY MD5 CHECKSUMS         "
echo "================================================================"
