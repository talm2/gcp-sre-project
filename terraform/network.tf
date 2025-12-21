# Enable the Compute Engine API.
# This API is required to create networks, firewalls, and VMs.
resource "google_project_service" "compute" {
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

# Enable the Container API (Kubernetes Engine).
# This API is required to create and manage GKE clusters.
resource "google_project_service" "container" {
  service            = "container.googleapis.com"
  disable_on_destroy = false
}

# Create the main VPC Network.
# We set auto_create_subnetworks to false because we want full control
# over our IP ranges and regions (Production Best Practice).
resource "google_compute_network" "vpc" {
  name                    = "${var.project_id}-vpc"
  auto_create_subnetworks = false
  depends_on              = [google_project_service.compute]
}

# Create a custom Subnet for the GKE cluster.
# This subnet defines the primary IP range for the Nodes (VMs).
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.project_id}-subnet"
  region        = var.region
  network       = google_compute_network.vpc.name
  ip_cidr_range = "10.0.0.0/16"

  # Secondary range for Pods (Containers).
  # GKE uses VPC-native networking, giving pods real VPC IPs.
  secondary_ip_range {
    range_name    = "pods-range"
    ip_cidr_range = "10.1.0.0/16"
  }

  # Secondary range for Services (ClusterIPs).
  # This isolates internal service traffic from pod traffic.
  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "10.2.0.0/16"
  }
}

# Create a Cloud Router.
# The Cloud Router controls route advertisements for the NAT gateway.
# It is a regional resource required for Cloud NAT to work.
resource "google_compute_router" "router" {
  name    = "${var.project_id}-router"
  region  = var.region
  network = google_compute_network.vpc.name
}

# Create a Cloud NAT (Network Address Translation).
# This allows our private GKE nodes to access the internet (e.g., to pull Docker images)
# without having public IP addresses themselves. This is a crucial security layer.
resource "google_compute_router_nat" "nat" {
  name                               = "${var.project_id}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}