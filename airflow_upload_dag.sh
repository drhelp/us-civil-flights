gcloud beta composer environments storage dags import \
    --environment airflow-main \
    --location europe-north1 \
    --source="airflow/dags/kaggle_to_gcs.py"