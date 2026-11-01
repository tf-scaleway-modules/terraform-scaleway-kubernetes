################################################################################
# Minimal Example - Scaleway Kubernetes Cluster
################################################################################

module "kubernetes" {
  source = "../.."

  # Project
  project_id = var.project_id

  # Network
  private_network_id = var.private_network_id

  # Cluster
  name               = "minimal-cluster"
  kubernetes_version = "1.34"

  # Node Pools
  node_pools = {
    default = {
      node_type = "DEV1-M"
      size      = 2
    }
  }
}
