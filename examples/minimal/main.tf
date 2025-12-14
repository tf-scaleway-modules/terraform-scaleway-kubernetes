################################################################################
# Minimal Example - Scaleway Kubernetes Cluster
################################################################################

module "kubernetes" {
  source = "../.."

  # Project
  organization_id = var.organization_id
  project_name    = var.project_name

  # Network
  private_network_id = var.private_network_id

  # Cluster
  name               = "minimal-cluster"
  kubernetes_version = "1.31"

  # Node Pools
  node_pools = {
    default = {
      node_type = "DEV1-M"
      size      = 2
    }
  }
}
