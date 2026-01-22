#!/bin/bash

# NAME: move_identical_media_duplicates.sh
# DESC: Recursively scans a directory for identical photo/video files (same content, different names allowed).
#       Keeps one copy in place and moves all other identical copies into "Duplicates" in the root folder.
#       Nothing is deleted.

# Usage:
#   chmod +x move_identical_media_duplicates.sh
#   ./move_identical_media_duplicates.sh
#   ./move_identical_media_duplicates.sh /path/to/folder

set -euo pipefail

ROOT_DIR="${1:-.}"
DUP_DIR="$ROOT_DIR/Duplicates"
mkdir -p "$DUP_DIR"

# Use Python for robust hashing + grouping (works with macOS default Bash 3.2)
# This handles spaces/newlines safely using null-delimited find output.
python3 - <<'PY' "$ROOT_DIR"
import os
import sys
import hashlib
import shutil

ROOT_DIR = os.path.abspath(sys.argv[1])
DUP_DIR = os.path.join(ROOT_DIR, "Duplicates")
os.makedirs(DUP_DIR, exist_ok=True)

PHOTO_EXTS = {".jpg",".jpeg",".png",".heic",".tif",".tiff",".gif",".bmp",".webp"}
VIDEO_EXTS = {".mp4",".mov",".m4v",".avi",".mkv",".wmv",".flv",".webm",".3gp"}
EXTS = PHOTO_EXTS | VIDEO_EXTS

def is_in_duplicates(path: str) -> bool:
    try:
        return os.path.commonpath([os.path.abspath(path), os.path.abspath(DUP_DIR)]) == os.path.abspath(DUP_DIR)
    except ValueError:
        return False

def sha256_file(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()

def collision_safe_dest(dest_dir: str, filename: str) -> str:
    base, ext = os.path.splitext(filename)
    candidate = os.path.join(dest_dir, filename)
    if not os.path.exists(candidate):
        return candidate
    i = 1
    while True:
        candidate = os.path.join(dest_dir, f"{base}_{i}{ext}")
        if not os.path.exists(candidate):
            return candidate
        i += 1

# Gather candidate files (recursive), skipping Duplicates folder entirely
candidates = []
for dirpath, dirnames, filenames in os.walk(ROOT_DIR):
    # Prevent descending into Duplicates
    dirnames[:] = [d for d in dirnames if os.path.abspath(os.path.join(dirpath, d)) != os.path.abspath(DUP_DIR)]

    for name in filenames:
        ext = os.path.splitext(name)[1].lower()
        if ext in EXTS:
            full = os.path.join(dirpath, name)
            if not is_in_duplicates(full):
                candidates.append(full)

# Group by (size, sha256)
seen = {}  # key -> first kept path
moved = 0

for path in candidates:
    try:
        size = os.path.getsize(path)
    except FileNotFoundError:
        continue  # file may have been moved during the run

    try:
        digest = sha256_file(path)
    except (FileNotFoundError, PermissionError) as e:
        print(f"Warning: could not hash file, skipping: {path}\n  Reason: {e}")
        continue

    key = (size, digest)

    if key not in seen:
        seen[key] = path
        continue

    # Move duplicates into Duplicates/, preserving relative folder structure
    rel_dir = os.path.relpath(os.path.dirname(path), ROOT_DIR)
    dest_dir = os.path.join(DUP_DIR, rel_dir)
    os.makedirs(dest_dir, exist_ok=True)

    dest = collision_safe_dest(dest_dir, os.path.basename(path))

    # Move
    try:
        shutil.move(path, dest)
        moved += 1
        print("Moved duplicate:")
        print(f"  From: {path}")
        print(f"  To:   {dest}\n")
    except Exception as e:
        print(f"Error: failed to move {path} -> {dest}\n  Reason: {e}")

print(f"Done: moved {moved} duplicate file(s) into: {DUP_DIR}")
PY