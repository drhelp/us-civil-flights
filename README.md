# US Civil Flights 2023 - Data Engineering Zoomcamp 2024 Final Project

This repository contains my final project for the completion of Data Engineering Zoomcamp by DataTalks.Club.

## Project description

This project aims to develop a robust data engineering pipeline focused on US civil flights data for year 2023, with the objective of building a comprehensive data warehouse that supports advanced analytics and visualization through a Business Intelligence (BI) tool. The goal is to enable stakeholders to make informed decisions by providing insights into flight patterns, performance, and trends.

## Source Data
Used dataset is Kaggle [US 2023 Civil Flights, delays, meteo and aircrafts](https://www.kaggle.com/datasets/bordanova/2023-us-civil-flights-delay-meteo-and-aircraft) which is obtained from Kagge via its API
It is complete dataset of US civil aviation 2023 containing :
- departure and arrival delays for each flight
- descriptions and delay times
- weather with rain, snow, pressure, temperature min/max/avg, wind - speed and direction for each airport
- associated airlines
- information for each plane with manufacturer, model and age.  

Dataset consist of 3 files in CSV format (comma-serated, 1 header row):
- US_flights_2023.csv: main table containing all flight information except weather
- weather_meteo_by_airport.csv: table containing weather data (temperatures, air pressure, snow cover, precipitation, wind strength and direction) for each airport and day of the year
- Cancelled_Diverted_2023.csv: table of cancellations and diverted flights for a dedicated analysis. 

## Tools / Tech Stack
The following components were used to implement the project:
- Data Extraction & Ingestion: **Python** (using Kaggle API and GCS library)
- Data Lake: **Google Cloud Storage**
- Workflow Management: **Google Cloud Composer** (managed Apache Airflow product in Google Cloud)
- Data Warehouse: **Google BigQuery**
- Data Transformation: **dbt cloud**
- Reporting & BI: **Google Looker Studio**
- Infrastructure as Code: **Terraform**
- Code Repository: **GitHub**

## Architecture Diagram
![Architecture](/images/US%20Civil%20Flights.png)

## Data Processing / Pipeline description

###  Data Extraction (EL steps)

Data is extracted from Kaggle using API and upload to Data Lake in Google Cloud Storage bucket. The code is written in Python and run through Google Cloud Composer (manager Apache Airflow)

There is one DAG in [/airflow/dags/kaggle_to_gcs.py](/airflow/dags/kaggle_to_gcs.py) which consist of 2 steps:
- **download_kaggle_dataset**: extract Kaggle dataset files using API and download to a local data folder availbe to Airflow server (it's actually a GCS bucket but mapped to Airflow FS as a local folder)
- **upload_to_gcs**: upload previously downloaded files to GCS bucket using Airflow's LocalFilesystemToGCSOperator 

As a results of this step we have source data (3 files) loaded to a Data Lake (GCS bucket)

### Data Processing (T step)

Data processing is done inside BigQuery and manager by **dbt** framework (powered by dbt cloud). All dbt models and settings are located in [/dbt](/dbt/) subfolder (git repor is linked to a dbt cloud project)

There are following steps in data transformation:
- **Access sources**. External tables are created in BigQuery using dbt_external_tables module. These external tables allow BigQuery to access source .csv files in GCS bucket as a relation tables. External tables are defined in [sources.yml](/dbt/models/sources.yml)
    - src_us_flights_2023: main flight table
    - src_cancelled_diverted_2023: cancelled flights
    - src_weather_meteo_by_airport: meteo data
- **Build staging models** (/models/stage): create 1-1 models that access source data without any transformation (except for column rename), materialized as view.
    - stg_us_flights: main flight table
    - stg_cancelled_flights: cancelled flights
    - stg_weather_meteo: meteo data
- Build marks (/models/marts): create fact & dimensional tables. Transformations are possible and data in materialized as a tables, considering physical design (partitioning and clustering)
    - **ft_flights**: main fact table for flights. Partitioned by 'Flight_Date' column (month granularity) and clustered by ['Airline','Tail_Number'] columns
    - **ft_weather_meteo**: meteo data. Small table so no need for partitioning/clustering
    - **ft_flights_meteo**: final data mart for BI/reporting which combines both flight data and relative meteo data in one table. Partitioned and clustered the same way as ft_flights

Here is a data lineage screen from dbt:
![data lineage](/images/dbt-data-lineage.png)

### BI (reporting & visualization)

Example dashboard is created in Google Looker Studio (former Google Data Sudio) using full ft_flights_meteo data mart as a dataset.
It shows some key metrics/statistics of 2023 flights in visual 1-page dashboard. 

The dashboard is made publicly available via the [following link](https://lookerstudio.google.com/reporting/37c6c96c-9d4b-4be6-88ec-83101bcedff3)

Here is the screenshot how it looks like:
![Dashboard](/images/US-Civil-Flight-Dashboard.png)


## Steps to reproduce:

### Local setup
Install the below tools on you PC:
- Terraform
- Google Cloud SDK
- Clone this repository to your local machine in the folder of your choice  
```git clone https://github.com/drhelp/us-civil-flights.git```

### Cloud setup
- Create/activate an account in Google Cloud and enable $300 90-days credit for new users (if not activated)
- In GCP (IAM & Admin), create a service principal with at least the following permissions:
    - BigQuery Admin
    - Storage Admin
    - Storage Object Admin  
Or you can simply grant Editor or Owner permissions for the whole Google Cloud
- Download new service principal authentication file (json) and save it under .google subfolder in this repo (e.g .google/core-computer-420516-90dd08235611.json)
- Ensure that the following APIs are enabled:
    - BigQuery API
    - Bigquery Storage API
    - Identity and Access Management (IAM) API
    - IAM Service Account Credentials API
    - Google Cloud Composer API v.2
- Go to Google Cloud IAM & Admin Page, there is a list of principals. Check 'Include Google-provided role grant' (unchecked by default) and find principal with "Cloud Composer Service Agent" in Name column. 
- Click "Edit' and grant it "Cloud Composer v2 API Service Agent Extension" role, overwise Cloud Composer enviroment won't be created with an error. Details can be found [here](https://stackoverflow.com/questions/75028496/cloud-composer-v2-api-service-agent-extension-role-might-be-missing), I've spent some time to fix this error!

### Kaggle setup
- Go to Kagge.com, create user account (if needed) and authenticate 
- Go to [Profile/Settings](https://www.kaggle.com/settings), and press "Create New Token", accept.
- You will get **kaggle.json** file downloaded. You'll need to save it to Airflow folder later

### Infastructure deployment using Terraform
- Replace Terraform variables in **terraform/variables.tf** with your values:
    - **credentials**: path to ervice principal JSON file saved earlier
    - **service_account**: full name of your service account
    - **project**: your Google Cloud project name (code, not numeric ID) - displayed on main Google Cloud console page
    - **project_number**: numeric project ID (also on main console page)
    - **region**: your prefered Google Cloud region where to create resources (e.g closer you geographically). Full list and be found [here](https://cloud.google.com/about/locations), but note that Cloud Composer (Managed Airflow) is not available in every region!
    - **data_lake_bucket**: name of Data Lake bucket in GCS to store source files downloaded from Kaggle
    - **storage_class**: can leave default value
    - **bq_dataset**: name of BigQuery dataset with DWH tables
- In **terraform/main.tf** change value of KAGGLE_USERNAME enviroment variable for Airflow to you Kagge User name (can be seen in profile)
- Run Terraform commands to create cloud infrastructure:
```
cd terraform
terraform init
terraform plan
terraform apply
cd ..
```
- Wait for commands to finish (creating Cloud Composer Airflow enviroment could take up to 30 mins!)
### Setup and run Airflow DAGS on Cloud Composer
- Go to Cloud Console, then find Compose - you should see your new Compose environment up&running, looks like this:
![composer](/images/composer-env.png)
- Clink on environment to enter into
- Click "Open DAGS Folder" button on the bar. You'll be moved to a GCS bucket UI for Airflow
- Inside dags/ create **cred/** subfolder
- Create "Upload files" and upload your *kaggle.json* to dags/cred/ folder. It's be accessed inside Airflow DAG to authenticate in Kaggle.
![dag](/images/composer-dags.png)
- Upload DAG(airflow/dags/kaggle_to_gcs.py) to Airflow using this commands (Replace **europe-north1** with your GCS region!):
```
gcloud auth login
gcloud beta composer environments storage dags import \
    --environment airflow-main \
    --location europe-north1 \
    --source="airflow/dags/kaggle_to_gcs.py"
```
- Go to Airflow UI (You need to click "OPEN AIRFLOW UI" on the top bar inside Cloum Composer Enviroment UI, just left to "OPEN DAGS FOLDER" button):
![](/images/composer-env-inside.png)
- Authenticate with your Google Acoount and you should see classic Airflow UI with "kaggle_to_gcs" in DAGS list
- Press 'trigger DAG' action (arrow symbol) to start DAG. You should see it successfully completed in few mins:
![airflow](/images/airflow.png)
- Source files are now in Data Lake (you can check GCS bucket)
![gcs](/images/gcs-bucket-dl.png)



### Setup & run dbt for data transformation
- Go to [dbt cloud](https://cloud.getdbt.com) and create account
- Create a new dbt Project and link in to this GitHub repo (you may need to fork it to your GitHub account in advance). Set Project subdirectory to **dbt**
- Inside project create new Google BigQuery connection using service account credentials json file. IMPORTANT: inside connection Optional Settings you need to set Location to you selected google region (same as in Terraform variable). Overwise, it would be US by-default and BigQuery would not be able to access GCS bucket through external tables if it is another region!
- You should by now have dbt cloud project linked to this repo with BigQuery connection
- Create external tables: run comman in dbt console
```
dbt run-operation stage_external_sources --vars "ext_full_refresh:true"
```
- Build DWH (models)
```
dbt run
```
By default dbt builds a dev enviroment (with your Google account name as dataset name). You can build target dataset name by creaing PROD enviroment:
- In dbt cloud go to "Deploy->Environments"
- Create new environment with type ="Deployment" and Dataset = target dataset name (=bq_dataset TF variable)
- Go to Deploy->Jobs, create and new job to build DWH (dbt run)
- Run this job and wait for it to succeed.

### Business Intelligence (Visualization)
 - Dashboard is available via the [following link](https://lookerstudio.google.com/reporting/37c6c96c-9d4b-4be6-88ec-83101bcedff3)
 - Create a copy ("..." -> Create copy")
 - Open copy, go edit mode
 - Change data source to your target BigQuery dataset


Have fun!

## Acknowledgements
A special thank you to DataTalks.Club for providing this incredible course! Also, thank you to the amazing community!