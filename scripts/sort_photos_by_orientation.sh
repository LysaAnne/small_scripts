#!/bin/bash

# NAME: sort_photos_by_orientation.sh
# DESC: Sorts photos in a folder into "Horizontal" and "Vertical" folders based on image orientation.

# Usage:
#   chmod +x sort_photos_by_orientation.sh
#   ./sort_photos_by_orientation.sh /path/to/dir

set -u

if [[ "$#" -ne 1 ]]; then
  echo "Error: you must provide exactly one folder path."
  echo ""
  echo "Usage:"
  echo './sort_photos_by_orientation.sh "/path/to/folder"'
  exit 1
fi

SOURCE_DIR="$1"

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "Error: folder does not exist:"
  echo "$SOURCE_DIR"
  exit 1
fi

# Require exiftool for reliable image dimension/orientation detection
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

H_DIR="$SOURCE_DIR/Horizontal"
V_DIR="$SOURCE_DIR/Vertical"

mkdir -p "$H_DIR" "$V_DIR"

PHOTO_EXTS=(jpg jpeg png heic tif tiff gif bmp webp)

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

file_list="$(mktemp)"
trap 'rm -f "$file_list"' EXIT

find_args=("$SOURCE_DIR")
if [[ "$recursive" = false ]]; then
  find_args+=(-maxdepth 1)
fi

find_expr=()
for ext in "${PHOTO_EXTS[@]}"; do
  if [[ "${#find_expr[@]}" -gt 0 ]]; then
    find_expr+=(-o)
  fi
  find_expr+=(-iname "*.${ext}")
done

find "${find_args[@]}" \
  -type d \( -path "$H_DIR" -o -path "$V_DIR" \) -prune \
  -o -type f \( "${find_expr[@]}" \) -print0 > "$file_list"

horizontal=0
vertical=0
skipped=0

while IFS= read -r -d '' file; do
  [[ -e "$file" ]] || continue

  width=$(
    exiftool -n -s -s -s -ImageWidth "$file" 2>/dev/null | head -n 1
  )
  height=$(
    exiftool -n -s -s -s -ImageHeight "$file" 2>/dev/null | head -n 1
  )
  orientation=$(
    exiftool -n -s -s -s -Orientation "$file" 2>/dev/null | head -n 1
  )

  if [[ -z "${width:-}" || -z "${height:-}" ]]; then
    echo "Warning: could not read dimensions for: $(basename "$file"). Skipping."
    skipped=$((skipped + 1))
    continue
  fi

  # EXIF orientations 5-8 mean the displayed image is rotated, so width/height swap.
  if [[ "${orientation:-}" =~ ^[0-9]+$ && "$orientation" -ge 5 && "$orientation" -le 8 ]]; then
    tmp="$width"
    width="$height"
    height="$tmp"
  fi

  target="$H_DIR"
  if [[ "$height" -gt "$width" ]]; then
    target="$V_DIR"
  fi

  if [[ "$(dirname "$file")" = "$target" ]]; then
    skipped=$((skipped + 1))
    continue
  fi

  move_with_collision_safe_name "$file" "$target"

  if [[ "$target" = "$V_DIR" ]]; then
    vertical=$((vertical + 1))
  else
    horizontal=$((horizontal + 1))
  fi
done < "$file_list"

total_moved=$((horizontal + vertical))

echo "Done: moved $total_moved photo file(s). Horizontal: $horizontal. Vertical: $vertical. Skipped $skipped file(s)."
