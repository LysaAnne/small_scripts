# Creates a LightRoom file name list
# Prints the names of the .jpg files inside the directory of the script
# filenames will be comma separated
# Excludes hidden ._ files (Mac)
find . -maxdepth 1 -type f -name "*.jpg" ! -name "._*" \
  | sed 's|^\./||' \
  | tr -d '\r' \
  | sed 's/\.[^.]*$//' \
  | tr '\n' ',' \
  | sed 's/,/, /g' \
  | sed 's/, $//'
