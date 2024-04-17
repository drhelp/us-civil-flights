variable "credentials" {
  default = "../.google/core-computer-420516-90dd08235611.json"
}

variable "service_account" {
  default = "data-project-account@core-computer-420516.iam.gserviceaccount.com"
}

variable "project" {
  description = "Google Project Name"
  default     = "core-computer-420516"
}

variable "project_number" {
  default = "314381478320"
}

variable "region" {
  description = "Region for GCP resources. Choose as per your location: https://cloud.google.com/about/locations"
  default     = "europe-north1"
  type        = string
}

variable "data_lake_bucket" {
  description = "Data Lake Bucket"
  default     = "od-us-civil-flights-dl-bucket"
}

variable "storage_class" {
  description = "Storage class type for your bucket. Check official docs for more info."
  default     = "STANDARD"
}

variable "bq_dataset" {
  description = "BigQuery Dataset that raw data (from GCS) will be written to"
  type        = string
  default     = "us_civil_flights_dwh"
}