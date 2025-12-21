# Enable the IAM Credentials API.
# This API is required for Workload Identity Federation to exchange tokens.
resource "google_project_service" "iam_credentials" {
  service            = "iamcredentials.googleapis.com"
  disable_on_destroy = false
}

# Create a Workload Identity Pool.
# A pool is a container for identity providers. We use it to group GitHub Actions identities.
resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "github-actions-pool-v2"
  display_name              = "GitHub Actions Pool"
  description               = "Identity pool for GitHub Actions"
  disabled                  = false
}

# Create a Workload Identity Provider.
# This tells GCP specifically to trust tokens issued by GitHub (OIDC).
resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-actions-provider-v2"
  display_name                       = "GitHub Actions Provider"
  description                        = "OIDC Provider for GitHub Actions"
  
  # Mapping GitHub claims (assertion) to GCP attributes (attribute).
  attribute_mapping = {
    "google.subject"             = "assertion.sub"
    "attribute.repository"       = "assertion.repository"
    "attribute.actor"            = "assertion.actor"
    "attribute.repository_owner" = "assertion.repository_owner"
  }

  # Condition: Only allow tokens where the repo owner is 'talm2'.
  # This satisfies the API requirement and adds security.
  attribute_condition = "attribute.repository_owner == 'talm2'"
  
  # The OIDC issuer URL for GitHub Actions.
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Create a Service Account for GitHub Actions.
# This is the actual identity that the pipeline will "impersonate".
resource "google_service_account" "github_actions" {
  account_id   = "github-actions-sa"
  display_name = "GitHub Actions Service Account"
  description  = "Service Account used by GitHub Actions for CI/CD"
}

# Allow the Workload Identity Pool to impersonate the Service Account.
# This is the "binding" that says: "If a token comes from this GitHub Repo, let it act as this Service Account."
resource "google_service_account_iam_member" "workload_identity_binding" {
  service_account_id = google_service_account.github_actions.name
  role               = "roles/iam.workloadIdentityUser"
  
  # IMPORTANT: Replace 'talm2/gcp-sre-project' with your ACTUAL GitHub username and repo name.
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/talm2/gcp-sre-project"
}

# Grant the Service Account permission to push to Artifact Registry.
resource "google_artifact_registry_repository_iam_member" "sa_repo_writer" {
  location   = google_artifact_registry_repository.repo.location
  repository = google_artifact_registry_repository.repo.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.github_actions.email}"
}

# Grant the Service Account permission to deploy to the GKE cluster.
resource "google_project_iam_member" "sa_gke_developer" {
  project = var.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# Output the Service Account email and Provider ID.
# We will need these values to configure the GitHub Actions workflow YAML later.
output "github_actions_service_account" {
  value = google_service_account.github_actions.email
}

output "workload_identity_provider" {
  value = google_iam_workload_identity_pool_provider.github_provider.name
}
