from datetime import datetime

from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import DAG

with DAG(
    dag_id="hello_pipeline",
    start_date=datetime(2026, 1, 1),
    schedule=None,
    catchup=False,
    tags=["demo"],
) as dag:
    download = BashOperator(task_id="download", bash_command="echo 'downloading CSVs...'; sleep 3")
    load_raw = BashOperator(task_id="load_raw", bash_command="echo 'loading raw...'; sleep 3")
    dbt_build = BashOperator(task_id="dbt_build", bash_command="echo 'running dbt...'; sleep 3")

    download >> load_raw >> dbt_build
