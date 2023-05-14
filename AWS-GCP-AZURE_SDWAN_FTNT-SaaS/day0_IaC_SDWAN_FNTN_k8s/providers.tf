#------------------------------------------------------------------------------------------------
# Terraform state
#------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 0.12"
}

#------------------------------------------------------------------------------------------------
# Deployment in AWS
#------------------------------------------------------------------------------------------------
provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = local.region["id"]
}

#------------------------------------------------------------------------------------------------
# Deployment in GCP
#------------------------------------------------------------------------------------------------
provider "google" {
  project      = var.project
  region       = local.gcp_region
  zone         = local.gcp_zone1
  access_token = var.gcp_token
}
provider "google-beta" {
  project      = var.project
  region       = local.gcp_region
  zone         = local.gcp_zone1
  access_token = var.gcp_token
}

#------------------------------------------------------------------------------------------------
# Deployment in Azure
#------------------------------------------------------------------------------------------------
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}