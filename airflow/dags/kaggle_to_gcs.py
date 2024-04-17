from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python_operator import PythonOperator
from airflow.providers.google.cloud.transfers.local_to_gcs import LocalFilesystemToGCSOperator
from kaggle.api.kaggle_api_extended import KaggleApi
import os

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2024, 4, 17),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

def download_kaggle_dataset():
    # Set up Kaggle API
    api = KaggleApi()
    api.authenticate()
    
    # Define the dataset path and download
    dataset = 'bordanova/2023-us-civil-flights-delay-meteo-and-aircraft'
    api.dataset_download_files(dataset, path='/home/airflow/gcs/data/us-civil-flights', unzip=True)

# Define the DAG
dag = DAG(
    'kaggle_to_gcs',
    default_args=default_args,
    description='Download Kaggle Dataset and upload to GCS',
    schedule_interval=timedelta(days=1),
)

download_dataset = PythonOperator(
    task_id='download_kaggle_dataset',
    python_callable=download_kaggle_dataset,
    dag=dag,
)

upload_to_gcs = LocalFilesystemToGCSOperator(
    task_id='upload_to_gcs',
    src='/home/airflow/gcs/data/us-civil-flights/*.csv',
    dst='data/',
    bucket='od-us-civil-flights-dl-bucket',
    gcp_conn_id='google_cloud_default',
    dag=dag,
)

download_dataset >> upload_to_gcs
