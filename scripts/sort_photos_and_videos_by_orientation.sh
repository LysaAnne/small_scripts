#!/bin/bash

# NAME: sort_photos_and_videos_by_orientation.sh
# DESC: Sorts media in a folder into "Photos" and "Videos". Videos are further sorted into "Videos/Horizontal" or "Videos/Vertical" based on filmed orientation.

# Usage:
#   chmod +x sort_photos_and_videos_by_orientation.sh
#   ./sort_photos_and_videos_by_orientation.sh              # current directory
#   ./sort_photos_and_videos_by_orientation.sh /path/to/dir # given directory

set -u

SOURCE_DIR="${1:-.}"

# Require exiftool for reliable video dimension/orientation detection
if ! command -v exiftool >/dev/null 2>&1; then
  echo "Error: exiftool is required but not installed."
  echo "macOS: brew install exiftool"
  echo "Debian/Ubuntu: sudo apt install libimage-exiftool-perl"
  exit 1
fi

shopt -s nullglob nocaseglob

PHOTOS_DIR="$SOURCE_DIR/Photos"
VIDEOS_DIR="$SOURCE_DIR/Videos"
H_DIR="$VIDEOS_DIR/Horizontal"
V_DIR="$VIDEOS_DIR/Vertical"

mkdir -p "$PHOTOS_DIR" "$H_DIR" "$V_DIR"

PHOTO_EXTS=(jpg jpeg png heic tif tiff gif bmp webp)
VIDEO_EXTS=(mp4 mov m4v avi mkv wmv flv webm 3gp)

move_with_collision_safe_name() {
  local src="$1"
  local dest_dir="$2"

  local base dest name ext i
  base="$(basename "$src")"
  dest="$dest_dir/$base"

  if [[ -e "$dest" ]]; then
    name="${base%.*}"
    ext="${base##*.}"
    i=1
    while [[ -e "$dest_dir/${name}_$i.$ext" ]]; do
      i=$((i + 1))
    done
    dest="$dest_dir/${name}_$i.$ext"
  fi

  mv "$src" "$dest"
}

# --- Photos: move into Photos/ ---
for ext in "${PHOTO_EXTS[@]}"; do
  for file in "$SOURCE_DIR"/*.${ext}; do
    [[ -e "$file" ]] || continue
    move_with_collision_safe_name "$file" "$PHOTOS_DIR"
  done
done

# --- Videos: detect orientation and move into Videos/Horizontal or Videos/Vertical ---
for ext in "${VIDEO_EXTS[@]}"; do
  for file in "$SOURCE_DIR"/*.${ext}; do
    [[ -e "$file" ]] || continue

    # Get best-available width/height + rotation from metadata.
    # exiftool may provide different tags depending on container/codec.
    width=$(
      exiftool -n -s -s -s -ImageWidth -TrackImageWidth -SourceImageWidth "$file" 2>/dev/null | head -n 1
    )
    height=$(
      exiftool -n -s -s -s -ImageHeight -TrackImageHeight -SourceImageHeight "$file" 2>/dev/null | head -n 1
    )
    rotation=$(
      exiftool -n -s -s -s -Rotation "$file" 2>/dev/null | head -n 1
    )

    # If rotation is 90/270, swap width/height for display orientation
    if [[ -n "${rotation:-}" ]]; then
      # rotation can be like 90, 180, 270, or -90
      rot_norm=$(( (rotation % 360 + 360) % 360 ))
      if [[ "$rot_norm" -eq 90 || "$rot_norm" -eq 270 ]]; then
        tmp="$width"
        width="$height"
        height="$tmp"
      fi
    fi

    # Decide target folder
    target="$H_DIR"
    if [[ -n "${width:-}" && -n "${height:-}" ]]; then
      # If height > width => Vertical
      if [[ "$height" -gt "$width" ]]; then
        target="$V_DIR"
      else
        target="$H_DIR"
      fi
    else
      # If metadata is missing, default to Horizontal and warn
      echo "Warning: could not read dimensions for: $(basename "$file"). Defaulting to Horizontal."
      target="$H_DIR"
    fi

    move_with_collision_safe_name "$file" "$target"
  done
done

echo "Done: photos moved to 'Photos', videos moved to 'Videos/Horizontal' or 'Videos/Vertical'."