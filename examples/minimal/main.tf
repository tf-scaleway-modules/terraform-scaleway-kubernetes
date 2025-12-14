################################################################################
# Minimal Example - Scaleway Kubernetes Cluster
################################################################################

module "kubernetes" {
  source = "../.."

  organization_id    = var.organization_id
  project_name       = var.project_name
  private_network_id = var.private_network_id

  name               = "minimal-cluster"
  kubernetes_version = "1.31"
  cni                = "cilium"

  node_pools = {
    default = {
      node_type = "DEV1-M"
      size      = 2
    }
  }
}
