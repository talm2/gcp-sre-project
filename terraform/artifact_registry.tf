# Enable the Artifact Registry API.
resource "google_project_service" "artifact_registry" {
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

# Create a Docker Repository in Artifact Registry.
resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = "sre-repo" # The name of the repo
  description   = "Docker repository for SRE project"
  format        = "DOCKER"

  depends_on = [google_project_service.artifact_registry]
}

# Output the repository URL so we know where to push images.
output "repository_url" {
  value = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.repo.repository_id}"
}