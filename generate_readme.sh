#!/usr/bin/env bash

echo "# Small Scripts" > README.md
echo "" >> README.md
echo "This repo contains small scripts I've created for my daily use. This overview has been automatically created." >> README.md
echo "" >> README.md

# Find alle scripts og markdown-filer i scripts/
find scripts/ -maxdepth 1 -type f \( \
    -name "*.sh" -o \
    -name "*.py" -o \
    -name "*.ps1" -o \
    -name "*.cmd" -o \
    -name "*.md" \
\) | while read -r file; do

    name=$(grep "^# NAME:" "$file" | sed 's/# NAME: //')
    desc=$(grep "^# DESC:" "$file" | sed 's/# DESC: //')

    # Titel
    if [ -n "$name" ]; then
        echo "## $name" >> README.md
    else
        echo "## $(basename "$file")" >> README.md
    fi

    # Beskrivelse
    if [ -n "$desc" ]; then
        echo "$desc" >> README.md
    else
        echo "(Ingen beskrivelse)" >> README.md
    fi

    echo "" >> README.md
done