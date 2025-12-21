    variable "project_id" {
      type        = string
      description = "The GCP project ID to deploy resources into."
    }

    variable "region" {
      type        = string
      description = "The primary GCP region for the resources."
      default     = "us-central1"
    }