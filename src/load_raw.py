"""Load Costa Rica police CSVs (2015-2026) into raw.police_reports."""
import csv
import glob
import io
import re

import psycopg2

EXPECTED_COLS = 11
NATIONALITY_IDX = 7  # the only column where we have seen an extra comma

conn = psycopg2.connect(host="localhost", dbname="crime", user="postgres", password="postgres")
cur = conn.cursor()
cur.execute("TRUNCATE raw.police_reports")  # makes the script safe to re-run

total = 0
for path in sorted(glob.glob("data/raw/policiales_*.csv")):
    year = int(re.search(r"(\d{4})", path).group(1))
    buf = io.StringIO()
    writer = csv.writer(buf)
    n = 0
    with open(path, encoding="latin1", newline="") as f:
        for row in csv.reader(f):
            if len(row) < EXPECTED_COLS:
                print(f"  {year}: SKIPPED short row ({len(row)} fields): {row}")
                continue
            if len(row) > EXPECTED_COLS:
                print(f"  {year}: fixing row with {len(row)} fields: {row}")
                extra = len(row) - EXPECTED_COLS
                merged = ",".join(row[NATIONALITY_IDX:NATIONALITY_IDX + extra + 1])
                row = row[:NATIONALITY_IDX] + [merged] + row[NATIONALITY_IDX + extra + 1:]
            writer.writerow(row + [year])
            n += 1
    buf.seek(0)
    cur.copy_expert("COPY raw.police_reports FROM STDIN WITH (FORMAT csv)", buf)
    print(year, n, "rows")
    total += n

conn.commit()
print("TOTAL", total)
