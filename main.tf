# 6. Upload your openapi.yaml configuration
resource "google_api_gateway_api_config" "api_cfg" {
  provider             = google-beta
  api                  = google_api_gateway_api.api.api_id
  
  # CHANGE THIS LINE: Use a prefix instead of a hardcoded ID
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

  # ADD THIS MAGIC BLOCK
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

  # ADD THIS MAGIC BLOCK HERE TOO
  lifecycle {
    create_before_destroy = true
  }
}
