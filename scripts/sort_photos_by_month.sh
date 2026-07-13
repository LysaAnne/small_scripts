#!/bin/bash

# NAME: sort_photos_by_month.sh
# DESC: Scans a directory and sorts photos and videos into folders named "YYYY.MM" based on capture date metadata, falling back to file modification date when metadata is missing

# Sort photos and videos into folders named YYYY.MM based on:
# 1) Capture date (EXIF/QuickTime metadata) when available
# 2) File modification date as fallback
#
# Usage:
#   chmod +x sort_photos_by_month.sh
#   ./sort_photos_by_month.sh /path/to/dir

if [[ "$#" -ne 1 ]]; then
  echo "Error: you must provide exactly one folder path."
  echo ""
  echo "Usage:"
  echo './sort_photos_by_month.sh "/path/to/folder"'
  exit 1
fi

SOURCE_DIR="$1"

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "Error: folder does not exist:"
  echo "$SOURCE_DIR"
  exit 1
fi

# Require exiftool for best results
if ! command -v exiftool >/dev/null 2>&1; then
  echo "Error: exiftool is required but not installed."
  echo "macOS: brew install exiftool"
  echo "Debian/Ubuntu: sudo apt install libimage-exiftool-perl"
  exit 1
fi

shopt -s nullglob nocaseglob

echo "Include files in subfolders?"
echo "1) No"
echo "2) Yes"
echo ""
read -r -p "Enter choice: " recursive_choice

if [[ "$recursive_choice" = "1" ]]; then
  recursive=false
elif [[ "$recursive_choice" = "2" ]]; then
  recursive=true
else
  echo "Invalid choice"
  exit 1
fi

# Common photo + video extensions (add more if you need)
MEDIA_EXTS=(
  "jpg" "jpeg" "png" "heic" "tif" "tiff" "gif"
  "mp4" "mov" "m4v" "avi" "mkv" "wmv" "flv" "webm" "3gp"
)

file_list="$(mktemp)"
trap 'rm -f "$file_list"' EXIT

find_args=("$SOURCE_DIR")
if [[ "$recursive" = false ]]; then
  find_args+=(-maxdepth 1)
fi

find_expr=()
for ext in "${MEDIA_EXTS[@]}"; do
  if [[ "${#find_expr[@]}" -gt 0 ]]; then
    find_expr+=(-o)
  fi
  find_expr+=(-iname "*.${ext}")
done

<<<<<<< Updated upstream
echo "Done: media has been sorted into YYYY.MM folders."
=======
find "${find_args[@]}" -type f \( "${find_expr[@]}" \) -print0 > "$file_list"

moved=0
skipped=0
folders_created=0

while IFS= read -r -d '' file; do
  [[ -e "$file" ]] || continue

  # Try to read a good "capture" timestamp.
  # - For photos: DateTimeOriginal
  # - For videos (QuickTime): CreateDate / MediaCreateDate / TrackCreateDate
  # - As a broad fallback: CreateDate
  # We pick the first non-empty result.
  dt=$(
    exiftool -s -s -s \
      -DateTimeOriginal \
      -CreateDate \
      -MediaCreateDate \
      -TrackCreateDate \
      "$file" 2>/dev/null | head -n 1
  )

  if [[ -n "$dt" ]]; then
    # Expected formats like "2025:12:31 10:22:33" or "2025:12:31 10:22:33+01:00"
    year=$(echo "$dt" | cut -d: -f1)
    month=$(echo "$dt" | cut -d: -f2)
  else
    # Fallback to file modification time (works on macOS/Linux)
    year=$(date -r "$file" +"%Y")
    month=$(date -r "$file" +"%m")
  fi

  target_dir="$SOURCE_DIR/$year.$month"

  if [[ "$(dirname "$file")" = "$target_dir" ]]; then
    skipped=$((skipped + 1))
    continue
  fi

  if [[ ! -d "$target_dir" ]]; then
    mkdir -p "$target_dir"
    folders_created=$((folders_created + 1))
  fi

  # Move file. If a file with the same name exists, append an incrementing suffix.
  base="$(basename "$file")"
  dest="$target_dir/$base"

  if [[ -e "$dest" ]]; then
    name="${base%.*}"
    ext2="${base##*.}"
    i=1
    while [[ -e "$target_dir/${name}_$i.$ext2" ]]; do
      i=$((i + 1))
    done
    dest="$target_dir/${name}_$i.$ext2"
  fi

  mv "$file" "$dest"
  moved=$((moved + 1))
done < "$file_list"

echo "Done: moved $moved media file(s) into YYYY.MM folders. Created $folders_created folder(s). Skipped $skipped file(s)."
>>>>>>> Stashed changes
