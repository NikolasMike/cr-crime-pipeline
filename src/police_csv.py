"""Shared reader for the Poder Judicial police CSVs (2015-2026)."""
import csv
import glob
import re

EXPECTED_COLS = 11
NATIONALITY_IDX = 7  # the only column where we have seen an extra comma


def csv_paths():
    return sorted(glob.glob("data/raw/policiales_*.csv"))


def read_year_file(path):
    """Return (year, rows) with every row fixed to exactly 11 fields."""
    year = int(re.search(r"(\d{4})", path).group(1))
    rows = []
    with open(path, encoding="latin1", newline="") as f:
        for row in csv.reader(f):
            if len(row) < EXPECTED_COLS:
                raise ValueError(f"{path}: row with {len(row)} fields (expected {EXPECTED_COLS}): {row}")
            if len(row) > EXPECTED_COLS:
                print(f"  {year}: fixing row with {len(row)} fields: {row}")
                extra = len(row) - EXPECTED_COLS
                merged = ",".join(row[NATIONALITY_IDX:NATIONALITY_IDX + extra + 1])
                row = row[:NATIONALITY_IDX] + [merged] + row[NATIONALITY_IDX + extra + 1:]
            rows.append(row)
    return year, rows
