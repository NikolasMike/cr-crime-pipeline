"""Load Costa Rica police CSVs (2015-2026) into BigQuery raw.police_reports."""
import csv
import io
import os

from google.cloud import bigquery

from police_csv import csv_paths, read_year_file

PROJECT = "cr-crime-pipeline"
LOCATION = "US"
KEYFILE = os.environ.get("GCP_KEYFILE", os.path.expanduser("~/.gcp/dbt-runner.json"))
TABLE = f"{PROJECT}.raw.police_reports"

COLUMNS = [
    "crime_type", "modus_operandi", "report_date", "victim_type", "victim_subtype",
    "victim_age_group", "unused_col", "victim_nationality", "province", "canton", "district",
]
schema = [bigquery.SchemaField(c, "STRING") for c in COLUMNS]
schema.append(bigquery.SchemaField("source_year", "INT64"))

client = bigquery.Client.from_service_account_json(KEYFILE, location=LOCATION)
dataset = bigquery.Dataset(f"{PROJECT}.raw")
dataset.location = LOCATION
client.create_dataset(dataset, exists_ok=True)

buf = io.StringIO()
writer = csv.writer(buf)
total = 0
for path in csv_paths():
    year, rows = read_year_file(path)
    for row in rows:
        writer.writerow(row + [year])
    print(year, len(rows), "rows")
    total += len(rows)

job_config = bigquery.LoadJobConfig(
    source_format=bigquery.SourceFormat.CSV,
    schema=schema,
    write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,  # safe to re-run
)
data = io.BytesIO(buf.getvalue().encode("utf-8"))
client.load_table_from_file(data, TABLE, job_config=job_config).result()

loaded = client.get_table(TABLE).num_rows
print("TOTAL prepared", total, "| in BigQuery", loaded)
if loaded != total:
    raise SystemExit(f"Row count mismatch: prepared {total}, loaded {loaded}")