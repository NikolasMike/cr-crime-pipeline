locals {
  datasets = toset(["raw", "analytics_dev", "analytics"])
}

resource "google_bigquery_dataset" "this" {
  for_each = local.datasets

  dataset_id                      = each.key
  location                        = "US"
  default_table_expiration_ms     = 5184000000 # 60 days, enforced by the BigQuery sandbox
  default_partition_expiration_ms = 5184000000 # same 60 days for partitioned tables

  lifecycle {
    prevent_destroy = true
  }
}
