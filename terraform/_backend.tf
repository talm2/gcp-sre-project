resource "google_storage_bucket" "tfstate" {
  name          = "${var.project_id}-tfstate"
  location      = var.region
  force_destroy = false

  # Enable versioning to keep a history of the state file for disaster recovery.
  # This allows rolling back to a previous state version if the file is corrupted.
  versioning {
    enabled = true
  }

  # Enforce using only IAM roles for access control, disabling legacy ACLs.
  # This is a security best practice to ensure consistent and auditable access.
  #uniform_bucket_level_access = true

  # Explicitly block any public access (like "allUsers") to this buIcket.
  # Ensures that sensitive state data can never be accidentally exposed to the internet.
  public_access_prevention = "enforced"

  # Prevent Terraform from destroying this resource to avoid accidental data loss.
  # To delete the bucket, this must be manually changed to false first.
  lifecycle {
    prevent_destroy = true
  }
}