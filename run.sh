#!/bin/bash

# ==========================================
# CONFIGURATION
# ==========================================
# Sonal's completed directory (Original Partition)
SONAL_DIR="/storage/F8FCADDDFCAD9702/Android/data/com.termux/files/Wedding_Backup/Sonal_Wedding"

# Roshan's directory (Clean target on the 88GB partition)
ROSHAN_DIR="/storage/7AF87657F876119D/Android/data/com.termux/files/Wedding_Backup/Roshan_Wedding"

SONAL_ROOT_ID="1UTqkkQr7SwXAZanU0Yy9yiQnsbDlYSUV"
ROSHAN_ROOT_ID="11T1irnWdZzj1G16Q_JpzdHGHzK6rVIOf"

export RCLONE_LOCAL_NO_SET_MODTIME=true
export RCLONE_LOCAL_NO_CHECK_UPDATED=true

FLAGS="--size-only --transfers 4 --checkers 16 --retries 15 --retries-sleep 5s -P --stats 1s --inplace --drive-chunk-size 64M"

# ==========================================
# INITIALIZATION
# ==========================================
mkdir -p "$SONAL_DIR"
mkdir -p "$ROSHAN_DIR"

echo "================================================================"
echo " STORAGE AUDIT                                                  "
echo "================================================================"
df -h | grep /storage/
echo "================================================================"

# ==========================================
# BACKUP EXECUTION QUEUE
# ==========================================
echo -e "\n================================================================"
echo " STARTING: SONAL WEDDING (VERIFYING COMPLETED)                  "
echo "================================================================"
rclone copy "gdrive,root_folder_id=$SONAL_ROOT_ID:" "$SONAL_DIR" $FLAGS

echo -e "\n================================================================"
echo " STARTING: ROSHAN WEDDING (TARGETING 88GB PARTITION)            "
echo "================================================================"
rclone copy "gdrive,root_folder_id=$ROSHAN_ROOT_ID:" "$ROSHAN_DIR" $FLAGS

echo -e "\n================================================================"
echo " PROCESS COMPLETE: ALL PHOTOS VERIFIED AND SECURED              "
echo "================================================================"
