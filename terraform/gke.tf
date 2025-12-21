# Define the GKE Autopilot Cluster.
# GKE Autopilot manages the worker nodes for us, optimizing for security and operations.
resource "google_container_cluster" "primary" {
  name     = "${var.project_id}-gke"
  location = var.region

  # Enable Autopilot mode.
  # This automatically manages node provisioning, scaling, and security patching.
  enable_autopilot = true

  # Connect to our custom VPC Network.
  # This ensures the cluster is isolated within our defined network boundary.
  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  # Configure Private Cluster settings.
  # This ensures the API server is accessible but secure.
  # For this learning project, we allow public access to the master endpoint
  # so you can run kubectl from your laptop easily, but we restrict it to authorized networks only later if needed.
  private_cluster_config {
    enable_private_nodes    = true   # Nodes have only internal IPs (Security Best Practice)
    enable_private_endpoint = false  # Master endpoint is public (easier for learning access)
  }

  # IP Allocation Policy for VPC-native networking.
  # We reference the secondary ranges we created in the subnet earlier.
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods-range"
    services_secondary_range_name = "services-range"
  }

  # Maintain the cluster but ensure Terraform doesn't delete it unnecessarily.
  deletion_protection = false # Set to true in real production to prevent accidents!
}

# Output the command to connect to the cluster.
# This makes it easy to just copy-paste the command after Terraform finishes.
output "kubectl_connection_command" {
  value = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region ${var.region} --project ${var.project_id}"
}