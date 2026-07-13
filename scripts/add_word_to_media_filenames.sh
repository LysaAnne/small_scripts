#!/bin/bash

# NAME: add_word_to_media_filenames.sh
# DESC: Renames photos and videos in a required folder by adding a prompted word before the file extension, using "-" space or "_" as delimiter.

# Usage:
#   chmod +x add_word_to_media_filenames.sh
#   ./add_word_to_media_filenames.sh /path/to/dir

set -u

if [[ "$#" -ne 1 ]]; then
  echo "Error: you must provide exactly one folder path."
  echo ""
  echo "Usage:"
  echo './add_word_to_media_filenames.sh "/path/to/folder"'
  exit 1
fi

SOURCE_DIR="$1"

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "Error: folder does not exist:"
  echo "$SOURCE_DIR"
  exit 1
fi

echo "Enter the word you want to add to each media filename:"
read -r word

if [[ -z "$word" ]]; then
  echo "Error: word cannot be empty."
  exit 1
fi

echo ""
echo "Choose delimiter:"
echo "1) -"
echo "2) space"
echo "3) _"
echo ""
read -r -p "Enter choice: " delimiter_choice

case "$delimiter_choice" in
  1)
    delimiter="-"
    ;;
  2)
    delimiter=" "
    ;;
  3)
    delimiter="_"
    ;;
  *)
    echo "Invalid choice"
    exit 1
    ;;
esac

shopt -s nullglob nocaseglob

echo ""
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

MEDIA_EXTS=(
  "jpg" "jpeg" "png" "heic" "tif" "tiff" "gif" "bmp" "webp"
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

find "${find_args[@]}" -type f \( "${find_expr[@]}" \) -print0 > "$file_list"

renamed=0
skipped=0

while IFS= read -r -d '' file; do
  [[ -e "$file" ]] || continue

  dir="$(dirname "$file")"
  base="$(basename "$file")"
  name="${base%.*}"
  file_ext="${base##*.}"
  suffix="${delimiter}${word}"

  if [[ "$name" == *"$suffix" ]]; then
    skipped=$((skipped + 1))
    continue
  fi

  dest="$dir/${name}${suffix}.${file_ext}"

  if [[ -e "$dest" ]]; then
    i=1
    while [[ -e "$dir/${name}${suffix}_$i.${file_ext}" ]]; do
      i=$((i + 1))
    done
    dest="$dir/${name}${suffix}_$i.${file_ext}"
  fi

  mv "$file" "$dest"
  renamed=$((renamed + 1))
  echo "Renamed: $base -> $(basename "$dest")"
done < "$file_list"

echo ""
echo "Done: renamed $renamed media file(s). Skipped $skipped file(s)."
