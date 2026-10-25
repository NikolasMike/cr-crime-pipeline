"""Load Costa Rica police CSVs (2015-2026) into raw.police_reports (Postgres)."""
import csv
import io

import psycopg2

from police_csv import csv_paths, read_year_file

conn = psycopg2.connect(host="localhost", dbname="crime", user="postgres", password="postgres")
cur = conn.cursor()
cur.execute("TRUNCATE raw.police_reports")  # makes the script safe to re-run

total = 0
for path in csv_paths():
    year, rows = read_year_file(path)
    buf = io.StringIO()
    writer = csv.writer(buf)
    for row in rows:
        writer.writerow(row + [year])
    buf.seek(0)
    cur.copy_expert("COPY raw.police_reports FROM STDIN WITH (FORMAT csv)", buf)
    print(year, len(rows), "rows")
    total += len(rows)

conn.commit()
print("TOTAL", total)
