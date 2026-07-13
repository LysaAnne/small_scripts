#!/bin/bash

# NAME: make_directory_for_each_month.sh
# DESC: Creates 12 folders with the name of each month of the year in the format "YYYY.MM NameOfMonth"

# Usage:
#   chmod +x make_directory_for_each_month.sh
#   ./make_directory_for_each_month.sh /path/to/dir

if [[ "$#" -ne 1 ]]; then
  echo "Error: you must provide exactly one folder path."
  echo ""
  echo "Usage:"
  echo './make_directory_for_each_month.sh "/path/to/folder"'
  exit 1
fi

TARGET_DIR="$1"

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "Error: folder does not exist:"
  echo "$TARGET_DIR"
  exit 1
fi

# Array of Danish month names
months=("Januar" "Februar" "Marts" "April" "Maj" "Juni" "Juli" "August" "September" "Oktober" "November" "December")

#Current year input
echo "Enter the Year you want the directories to be named after:"
read -r year

if [[ ! "$year" =~ ^[0-9]{4}$ ]]; then
  echo "Error: year must be four digits, for example 2026."
  exit 1
fi

# Loop through 12 months
for i in {1..12}; do
  # Format the month number with leading zero if necessary
  month_num=$(printf "%02d" $i)
  
  # Create the directory with the format 2023.MM MonthNameInDanish
  mkdir "$TARGET_DIR/$year.${month_num} ${months[$((i-1))]}"
done

echo "Directories created successfully!"
