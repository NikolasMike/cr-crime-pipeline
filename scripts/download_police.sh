#!/bin/bash
# Downloads Costa Rica police statistics (Poder Judicial open data), 2015-2026
BASE="https://pjcrdatosabiertos.blob.core.windows.net/datosabiertos/PJCROD_POLICIALES_V1"
mkdir -p data/raw

for YEAR in {2015..2026}; do
  FILE="data/raw/policiales_${YEAR}.csv"
  if [ -f "$FILE" ]; then
    echo "$YEAR already downloaded, skipping"
  else
    echo "Downloading $YEAR..."
    curl -fL -o "$FILE" "$BASE/PJCROD_POLICIALES_V1-${YEAR}.csv"
  fi
done
