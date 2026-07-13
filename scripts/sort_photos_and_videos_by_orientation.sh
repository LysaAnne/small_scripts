#!/bin/bash

# NAME: sort_photos_and_videos_by_orientation.sh
# DESC: Sorts media in a folder into "Photos" and "Videos". Videos are further sorted into "Videos/Horizontal" or "Videos/Vertical" based on filmed orientation.

# Usage:
#   chmod +x sort_photos_and_videos_by_orientation.sh
#   ./sort_photos_and_videos_by_orientation.sh /path/to/dir

set -u

if [[ "$#" -ne 1 ]]; then
  echo "Error: you must provide exactly one folder path."
  echo ""
  echo "Usage:"
  echo './sort_photos_and_videos_by_orientation.sh "/path/to/folder"'
  exit 1
fi

SOURCE_DIR="$1"

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "Error: folder does not exist:"
  echo "$SOURCE_DIR"
  exit 1
fi

# Require exiftool for reliable video dimension/orientation detection
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

PHOTOS_DIR="$SOURCE_DIR/Photos"
VIDEOS_DIR="$SOURCE_DIR/Videos"
H_DIR="$VIDEOS_DIR/Horizontal"
V_DIR="$VIDEOS_DIR/Vertical"

mkdir -p "$PHOTOS_DIR" "$H_DIR" "$V_DIR"

PHOTO_EXTS=(jpg jpeg png heic tif tiff gif bmp webp)
VIDEO_EXTS=(mp4 mov m4v avi mkv wmv flv webm 3gp)
MEDIA_EXTS=("${PHOTO_EXTS[@]}" "${VIDEO_EXTS[@]}")

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

is_photo_ext() {
  local ext="$1"
  local photo_ext

  for photo_ext in "${PHOTO_EXTS[@]}"; do
    if [[ "$ext" = "$photo_ext" ]]; then
      return 0
    fi
  done

  return 1
}

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

find "${find_args[@]}" \
  -type d \( -path "$PHOTOS_DIR" -o -path "$VIDEOS_DIR" \) -prune \
  -o -type f \( "${find_expr[@]}" \) -print0 > "$file_list"

photos_moved=0
videos_horizontal=0
videos_vertical=0
skipped=0

while IFS= read -r -d '' file; do
  [[ -e "$file" ]] || continue

  ext="$(printf '%s' "${file##*.}" | tr '[:upper:]' '[:lower:]')"

  if is_photo_ext "$ext"; then
    move_with_collision_safe_name "$file" "$PHOTOS_DIR"
    photos_moved=$((photos_moved + 1))
    continue
  fi

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
      videos_vertical=$((videos_vertical + 1))
    else
      target="$H_DIR"
      videos_horizontal=$((videos_horizontal + 1))
    fi
  else
    # If metadata is missing, default to Horizontal and warn
    echo "Warning: could not read dimensions for: $(basename "$file"). Defaulting to Horizontal."
    target="$H_DIR"
    videos_horizontal=$((videos_horizontal + 1))
  fi

  if [[ "$(dirname "$file")" = "$target" ]]; then
    skipped=$((skipped + 1))
    continue
  fi

  move_with_collision_safe_name "$file" "$target"
done < "$file_list"

total_moved=$((photos_moved + videos_horizontal + videos_vertical - skipped))

echo "Done: moved $total_moved media file(s). Photos: $photos_moved. Horizontal videos: $videos_horizontal. Vertical videos: $videos_vertical. Skipped $skipped file(s)."
