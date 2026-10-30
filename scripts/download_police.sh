#!/bin/bash
# Downloads Costa Rica police statistics (Poder Judicial open data), 2015 to the current year.
# Past years are downloaded once; the current year is refreshed on every run because the file keeps growing.
set -euo pipefail

BASE="https://pjcrdatosabiertos.blob.core.windows.net/datosabiertos/PJCROD_POLICIALES_V1"
CURRENT_YEAR=$(date +%Y)
mkdir -p data/raw

for YEAR in $(seq 2015 "$CURRENT_YEAR"); do
  FILE="data/raw/policiales_${YEAR}.csv"
  if [ -f "$FILE" ] && [ "$YEAR" -ne "$CURRENT_YEAR" ]; then
    echo "$YEAR already downloaded, skipping"
    continue
  fi
  echo "Downloading $YEAR..."
  if curl -fL -o "$FILE.tmp" "$BASE/PJCROD_POLICIALES_V1-${YEAR}.csv"; then
    mv "$FILE.tmp" "$FILE"
  else
    rm -f "$FILE.tmp"
    if [ "$YEAR" -eq "$CURRENT_YEAR" ]; then
      echo "WARNING: could not download $YEAR, keeping the existing file (if any)"
    else
      echo "ERROR: could not download $YEAR" >&2
      exit 1
    fi
  fi
done
