locals {
  datasets = {
    raw           = "Police reports exactly as published, every column as text."
    analytics_dev = "dbt development target, used to test changes before production."
    analytics     = "dbt production target: staging views, intermediate models and marts."
  }
}

resource "google_bigquery_dataset" "this" {
  for_each = local.datasets

  dataset_id                      = each.key
  description                     = each.value
  location                        = "US"
  default_table_expiration_ms     = 5184000000 # 60 days, enforced by the BigQuery sandbox
  default_partition_expiration_ms = 5184000000 # same 60 days for partitioned tables

  lifecycle {
    prevent_destroy = true
  }
}
