    terraform {
      required_version = ">= 1.0"

      required_providers {
    # The Google Provider allows Terraform to interact with GCP APIs (Compute, GKE, etc.)
        google = {
          source  = "hashicorp/google"
          version = "~> 5.0"
        }
      }

  # Configure the Backend to store the state file in a GCS bucket.
  # This allows for shared state and locking, essential for teams.
      backend "gcs" {
    bucket = "sre-portfolio-project-481507-tfstate"
        prefix = "terraform/state"
      }
    }

    provider "google" {
      project = var.project_id
      region  = var.region
    }
