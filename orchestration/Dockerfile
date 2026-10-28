FROM apache/airflow:3.3.2

USER root
RUN mkdir -p /opt/pipeline && chown airflow:0 /opt/pipeline
USER airflow

# Pipeline dependencies (dbt, BigQuery client...) in their own venv,
# separate from Airflow's Python, installed from the repo lockfile.
COPY --chown=airflow:0 pyproject.toml uv.lock /opt/pipeline/
RUN pip install --no-cache-dir uv \
 && cd /opt/pipeline \
 && UV_PROJECT_ENVIRONMENT=/opt/pipeline/.venv uv sync --locked --no-dev --no-install-project
