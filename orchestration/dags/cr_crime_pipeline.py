from datetime import datetime, timedelta

from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import DAG

PROJECT = "/opt/airflow/project"
VENV = "/opt/pipeline/.venv/bin"

default_args = {
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
}

with DAG(
    dag_id="cr_crime_pipeline",
    description="Costa Rica police reports: download, load raw into BigQuery, dbt build (prod)",
    start_date=datetime(2026, 1, 1),
    schedule="@monthly",
    catchup=False,
    default_args=default_args,
    tags=["cr-crime", "elt"],
) as dag:
    download = BashOperator(
        task_id="download",
        # trailing space: Airflow treats a command ending in ".sh" as a template file name
        bash_command=f"cd {PROJECT} && bash scripts/download_police.sh ",
    )
    load_raw = BashOperator(
        task_id="load_raw_bigquery",
        bash_command=f"cd {PROJECT} && {VENV}/python src/load_raw_bq.py",
    )
    dbt_deps = BashOperator(
        task_id="dbt_deps",
        bash_command=f"cd {PROJECT}/cr_crime && {VENV}/dbt deps",
    )
    dbt_build = BashOperator(
        task_id="dbt_build",
        bash_command=f"cd {PROJECT}/cr_crime && {VENV}/dbt build --target bq_prod",
        retries=0,
    )

    download >> load_raw >> dbt_deps >> dbt_build
