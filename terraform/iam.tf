locals {
  dbt_runner_roles = toset(["roles/bigquery.dataEditor", "roles/bigquery.jobUser"])
}

resource "google_service_account" "dbt_runner" {
  account_id   = "dbt-runner"
  display_name = "dbt-runner"
}

resource "google_project_iam_member" "dbt_runner" {
  for_each = local.dbt_runner_roles

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.dbt_runner.email}"
}
