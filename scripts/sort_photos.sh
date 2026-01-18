#!/bin/bash

# NAME: sort_photos.sh
# DESC: Scans a directory and sorts photos and videos into folders named "YYYY.MM" based on capture date metadata, falling back to file modification date when metadata is missing

# Sort photos and videos into folders named YYYY.MM based on:
# 1) Capture date (EXIF/QuickTime metadata) when available
# 2) File modification date as fallback
#
# Usage:
#   chmod +x sort_photos.sh
#   ./sort_photos.sh                # sorts current directory
#   ./sort_photos.sh  /path/to/dir   # sorts given directory

SOURCE_DIR="${1:-.}"

# Require exiftool for best results
if ! command -v exiftool >/dev/null 2>&1; then
  echo "Error: exiftool is required but not installed."
  echo "macOS: brew install exiftool"
  echo "Debian/Ubuntu: sudo apt install libimage-exiftool-perl"
  exit 1
fi

shopt -s nullglob nocaseglob

# Common photo + video extensions (add more if you need)
MEDIA_EXTS=(
  "jpg" "jpeg" "png" "heic" "tif" "tiff" "gif"
  "mp4" "mov" "m4v" "avi" "mkv" "wmv" "flv" "webm" "3gp"
)

for ext in "${MEDIA_EXTS[@]}"; do
  for file in "$SOURCE_DIR"/*.${ext}; do
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
    mkdir -p "$target_dir"

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
  done
done

echo "Done: media has been sorted into YYYY.MM folders."