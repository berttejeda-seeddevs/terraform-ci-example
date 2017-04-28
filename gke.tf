variable "gke_node_count" {
  default = 3
}

variable "gke_admin_password" {
  description = "Password for the HTTP Kubernetes API"
}

data "google_compute_zones" "available" {
  region = "${var.region}"
}

resource "google_service_account" "gke-node" {
  project      = "${google_project.project.project_id}"
  account_id   = "gke-node"
  display_name = "GKE Node"
}

data "google_iam_policy" "gke-node" {
  binding {
    role = "roles/storage.objectViewer"

    members = [
      "serviceAccount:${google_service_account.gke-node.email}",
    ]
  }
}

resource "google_container_cluster" "cluster1" {
  project = "${google_project.project.project_id}"

  name = "cluster1"
  zone = "${data.google_compute_zones.available.names[0]}"
  initial_node_count = "${var.gke_node_count}"

  #additional_zones = ["${slice(data.google_compute_zones.available.names, 1,  length(data.google_compute_zones.available.names))}"]

  master_auth {
    username = "admin"
    password = "${var.gke_admin_password}"
  }

  node_config {
    service_account = "${google_service_account.gke-node.email}"

    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

output "cluster_endpoint" {
  value = "https://admin:${var.gke_admin_password}@${google_container_cluster.cluster1.endpoint}"
}

output "cluster_zone" {
  value = "${google_container_cluster.cluster1.zone}"
}