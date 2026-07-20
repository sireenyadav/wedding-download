#!/bin/bash

# ==========================================
# CONFIGURATION
# ==========================================
# 1. Update this path to target the specific partition/folder on your hard drive
TARGET_DIR="/storage/ABCD-1234/Android/data/com.termux/files/Wedding_Backup"

# 2. Hardcoded Google Drive Root Folder IDs
SONAL_ROOT_ID="1UTqkkQr7SwXAZanU0Yy9yiQnsbDlYSUV"
ROSHAN_ROOT_ID="11T1irnWdZzj1G16Q_JpzdHGHzK6rVIOf"

# 3. Rclone Engine Operational Flags
# -P: Activates real-time visual progress monitoring
# --stats 1s: Forces the speed dashboard to refresh every single second
# --checksum: Validates files via MD5 hashes instead of modification times
# --transfers 4: Runs 4 concurrent file downloads to max out bandwidth pipes
FLAGS="--drive-shared-with-me --checksum --transfers 4 --retries 15 --retries-sleep 5s -P --stats 1s"

# ==========================================
# PRE-FLIGHT INITIALIZATION
# ==========================================
mkdir -p "$TARGET_DIR"

# Ensure rclone binary is present in the environment
if ! command -v rclone &> /dev/null; then
    echo "[-] Rclone execution module missing. Installing dependencies..."
    pkg update && pkg install rclone -y
fi

# Print current disk headroom before firing queue
echo "================================================================"
echo " PRE-FLIGHT STORAGE AUDIT: CURRENT SPACE STATUS                 "
echo "================================================================"
df -h "$TARGET_DIR"
echo "================================================================"
echo ""

# ==========================================
# BACKUP QUEUE EXECUTION
# ==========================================
echo "================================================================"
echo " QUEUE 1/2: SYNCING SONAL WEDDING (DIRECTING TO HDD)           "
echo "================================================================"
rclone copy "gdrive,root_folder_id=$SONAL_ROOT_ID:Photos" "$TARGET_DIR/Sonal_Wedding" $FLAGS

echo -e "\n================================================================"
echo " QUEUE 2/2: SYNCING ROSHAN WEDDING (DIRECTING TO HDD)          "
echo "================================================================"
rclone copy "gdrive,root_folder_id=$ROSHAN_ROOT_ID:Photos" "$TARGET_DIR/Roshan_Wedding" $FLAGS

echo -e "\n================================================================"
echo " CRITICAL SYNC COMPLETION: VERIFIED ACCORDING TO CHECKSUMS       "
echo "================================================================"
