terraform {
  backend "gcs" {
    bucket  = "ibm-api-hub-tf-state-4002"
    prefix  = "terraform/state"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = "ibm-api-hub-4002" 
  region  = "europe-central2"    
}

provider "google-beta" {
  project = "ibm-api-hub-4002" 
  region  = "europe-central2"    
}

# ==========================================
# BACKEND INFRASTRUCTURE
# ==========================================

# 1. Provision a BigQuery Dataset for Analytics
resource "google_bigquery_dataset" "analytics_dataset" {
  dataset_id    = "api_analytics"
  project       = "ibm-api-hub-4002"  # <-- Explicit project ID to prevent 403 Access Denied
  friendly_name = "API Analytics Dataset"
  description   = "Stores aggregated data from the API Hub"
  location      = "EU"
}

# 2. Provision a Cloud Run Service (Serverless Backend)
resource "google_cloud_run_service" "api_backend" {
  name     = "ibm-api-hub-backend"
  location = "europe-central2"

  template {
    spec {
      containers {
        image = "gcr.io/ibm-api-hub-4002/api-hub-image:latest" 
        ports {
          container_port = 8000
        }
      }
    }
  }
}

# ==========================================
# API GATEWAY & SECURITY INFRASTRUCTURE
# ==========================================

# 3. Create a dedicated Service Account for the Gateway
resource "google_service_account" "gateway_sa" {
  account_id   = "api-gateway-sa"
  display_name = "API Gateway Invoker"
}

# 4. Grant ONLY the Gateway permission to invoke your Cloud Run service
resource "google_cloud_run_service_iam_member" "gateway_invoker" {
  service  = google_cloud_run_service.api_backend.name
  location = google_cloud_run_service.api_backend.location
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.gateway_sa.email}"
}

# 5. Create the API definition
resource "google_api_gateway_api" "api" {
  provider = google-beta
  api_id   = "ibm-api-hub"
}

# 6. Upload your openapi.yaml configuration
resource "google_api_gateway_api_config" "api_cfg" {
  provider             = google-beta
  api                  = google_api_gateway_api.api.api_id
  
  # Use prefix instead of hardcoded ID for zero-downtime updates
  api_config_id_prefix = "ibm-api-hub-cfg-"

  openapi_documents {
    document {
      path     = "openapi.yaml"
      contents = filebase64("openapi.yaml")
    }
  }
  
  gateway_config {
    backend_config {
      google_service_account = google_service_account.gateway_sa.email
    }
  }

  # Magic block to prevent the Error 9 Immutable Loop
  lifecycle {
    create_before_destroy = true
  }
}

# 7. Deploy the physical Gateway to Belgium
resource "google_api_gateway_gateway" "api_gw" {
  provider   = google-beta
  gateway_id = "ibm-api-hub-gateway-eu"
  api_config = google_api_gateway_api_config.api_cfg.id
  region     = "europe-west1"

  # Magic block to prevent the Error 9 Immutable Loop
  lifecycle {
    create_before_destroy = true
  }
}
