#!/bin/bash

# NAME: make_directory_for_each_month.sh
# DESC: Creates 12 folders with the name of each month of the year in the format "YYYY.MM NameOfMonth"

# Array of Danish month names
months=("Januar" "Februar" "Marts" "April" "Maj" "Juni" "Juli" "August" "September" "Oktober" "November" "December")

#Current year input
echo "Enter the Year you want the directories to be named after:"
read year

# Loop through 12 months
for i in {1..12}; do
  # Format the month number with leading zero if necessary
  month_num=$(printf "%02d" $i)
  
  # Create the directory with the format 2023.MM MonthNameInDanish
  mkdir "$year.${month_num} ${months[$((i-1))]}"
done

echo "Directories created successfully!"
