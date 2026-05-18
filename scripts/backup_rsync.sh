# NAME: backup_rsync.sh
# DESC: Safe rsync backup script for external harddrives on Mac/Linux

#!/bin/bash

# Stop script immediately if a command fails
set -e

# Script requires exactly two arguments:
# 1) Source path
# 2) Destination path
if [ "$#" -ne 2 ]; then
  echo "ERROR: Missing source and destination paths."
  echo ""
  echo "You must run the script with exactly two paths:"
  echo "1) Source path"
  echo "2) Destination path"
  echo ""
  echo "Usage:"
  echo './backup_rsync.sh "SOURCE" "DESTINATION"'
  echo ""
  echo "Example:"
  echo './backup_rsync.sh "/Volumes/01 RAW/Test backup" "/Volumes/02.4_RAW/Test backup"'
  echo ""
  echo "Tip:"
  echo "Use TAB autocomplete in the terminal to find the correct paths."
  exit 1
fi

# Save command arguments as variables
SOURCE="$1"
DEST="$2"

echo "PHOTO BACKUP"
echo "============"
echo ""

# Backup mode selection
echo "Select backup mode:"
echo "1) Normal backup"
echo "   Copies new and changed files only."
echo "   Existing files on destination are kept."
echo ""

echo "2) Mirror backup"
echo "   Makes destination identical to source."
echo "   Files missing from source will be deleted on destination."
echo ""

read -p "Enter choice: " mode

echo ""

# Optional dry run before actual backup
echo "Run dry run first?"
echo "1) Yes"
echo "2) No"
echo ""

read -p "Enter choice: " dryrun_choice

echo ""
echo "SOURCE:"
echo "$SOURCE"
echo ""
echo "DESTINATION:"
echo "$DEST"
echo ""

# Verify source directory exists
if [ ! -d "$SOURCE" ]; then
  echo "ERROR: Source does not exist"
  exit 1
fi

# Verify destination directory exists
if [ ! -d "$DEST" ]; then
  echo "ERROR: Destination does not exist"
  exit 1
fi

# Show first few files in source
echo "Source contents:"
echo ""

ls "$SOURCE" | head

echo ""

# Show first few files in destination
echo "Destination contents:"
echo ""

ls "$DEST" | head

echo ""

# Create log directory if it does not exist
LOG_DIR="$HOME/backup-logs"
mkdir -p "$LOG_DIR"

# Create timestamped log filename
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
LOG="$LOG_DIR/backup-$DATE.log"

# Default dry run setting
RUN_DRYRUN=false

# Parse dry run selection
if [ "$dryrun_choice" = "1" ]; then
  RUN_DRYRUN=true
elif [ "$dryrun_choice" = "2" ]; then
  RUN_DRYRUN=false
else
  echo "Invalid choice"
  exit 1
fi

# NORMAL BACKUP
if [ "$mode" = "1" ]; then

  # Optional dry run
  if [ "$RUN_DRYRUN" = true ]; then
    echo "Running DRY RUN..."
    echo ""

    # rsync dry run:
    # -a = archive mode
    # -v = verbose
    # -h = human readable sizes
    # -n = dry run (no actual changes)
    # --exclude = skips unwanted Mac metadata files
    # --partial-dir = stores partial files safely
    # --progress = shows live progress
    # --stats = shows transfer statistics
    rsync -avhn \
      --exclude=".DS_Store" \
      --exclude="._*" \
      --partial-dir=.rsync-partial \
      --progress \
      --stats \
      "$SOURCE/" "$DEST/"

    echo ""
  fi

  # Require explicit confirmation
  read -p "Type YES to start backup: " confirm

  if [ "$confirm" != "YES" ]; then
    echo "Cancelled"
    exit 0
  fi

  # Actual backup
  # caffeinate -i prevents the Mac from going to sleep while rsync is running
  caffeinate -i rsync -avh \
    --exclude=".DS_Store" \
    --exclude="._*" \
    --partial-dir=.rsync-partial \
    --progress \
    --stats \
    "$SOURCE/" "$DEST/" | tee "$LOG"

# MIRROR BACKUP
elif [ "$mode" = "2" ]; then

  echo ""
  echo "WARNING: Mirror mode deletes files on destination"
  echo "that do not exist on source."
  echo ""

  # Extra warning if mirror is used without dry run
  if [ "$RUN_DRYRUN" = false ]; then
    echo "WARNING: You selected MIRROR mode WITHOUT dry run."
    echo "This can permanently delete files if source/destination are wrong."
    echo ""

    read -p "Type I UNDERSTAND to continue: " safety_confirm

    if [ "$safety_confirm" != "I UNDERSTAND" ]; then
      echo "Cancelled"
      exit 0
    fi

    echo ""
  fi

  # Optional dry run
  if [ "$RUN_DRYRUN" = true ]; then
    echo "Running DRY RUN..."
    echo ""

    # rsync dry run:
    # -a = archive mode
    # -v = verbose
    # -h = human readable sizes
    # -n = dry run (no actual changes)
    # --exclude = skips unwanted Mac metadata files
    # --partial-dir = stores partial files safely
    # --delete = removes files on destination that do not exist on source
    # --progress = shows live progress
    # --stats = shows transfer statistics
    rsync -avhn \
      --exclude=".DS_Store" \
      --exclude="._*" \
      --partial-dir=.rsync-partial \
      --delete \
      --progress \
      --stats \
      "$SOURCE/" "$DEST/"

    echo ""
  fi

  # Require stronger confirmation for mirror mode
  read -p "Type MIRROR to continue: " confirm

  if [ "$confirm" != "MIRROR" ]; then
    echo "Cancelled"
    exit 0
  fi

  # Actual mirror backup
  # caffeinate -i prevents the Mac from going to sleep while rsync is running
  caffeinate -i rsync -avh \
    --exclude=".DS_Store" \
    --exclude="._*" \
    --partial-dir=.rsync-partial \
    --delete \
    --progress \
    --stats \
    "$SOURCE/" "$DEST/" | tee "$LOG"

else
  echo "Invalid choice"
  exit 1
fi

echo ""
echo "Backup completed"
echo "Log file:"
echo "$LOG"