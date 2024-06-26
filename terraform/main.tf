terraform {
  required_version = ">= 1.0"
  backend "local" {} # Can change from "local" to "gcs" (for google) or "s3" (for aws), if you would like to preserve your tf-state online
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

provider "google" {
  project     = var.project
  region      = var.region
  credentials = file(var.credentials) # Use this if you do not want to set env-var GOOGLE_APPLICATION_CREDENTIALS
}

resource "google_storage_bucket" "data-lake-bucket" {
  name     = var.data_lake_bucket # Concatenating DL bucket & Project name for unique naming
  location = var.region

  # Optional, but recommended settings:
  storage_class               = var.storage_class
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 30 // days
    }
  }
  force_destroy = true
}

# DWH
# Ref: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_dataset
resource "google_bigquery_dataset" "bq_dwh" {
  dataset_id = var.bq_dataset
  project    = var.project
  location   = var.region
}

resource "google_composer_environment" "airflow" {
  name   = "airflow-main"
  region = var.region

  config {
    software_config {
      image_version = "composer-2.6.6-airflow-2.7.3"
      pypi_packages = {
        "kaggle" = ""
      }
      env_variables = {
        "KAGGLE_KEY" = "/home/airflow/dags/conn/kaggle.json"
        "KAGGLE_USERNAME" = "olegdobretsov"
      }
    }
    node_config {
      service_account = var.service_account
    }
  }

}