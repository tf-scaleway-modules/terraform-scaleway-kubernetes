################################################################################
# Complete Example - Scaleway Kubernetes Cluster
################################################################################

module "kubernetes" {
  source = "../.."

  organization_id    = var.organization_id
  project_name       = var.project_name
  private_network_id = var.private_network_id

  name               = "production-cluster"
  description        = "Production Kubernetes cluster"
  kubernetes_version = "1.31"
  cni                = "cilium"
  tags               = ["env:production", "team:platform", "managed-by:terraform"]

  delete_additional_resources = true

  # Auto upgrade configuration
  auto_upgrade = {
    enabled                       = true
    maintenance_window_start_hour = 3
    maintenance_window_day        = "sunday"
  }

  # Cluster autoscaler configuration
  autoscaler_config = {
    disable_scale_down               = false
    scale_down_delay_after_add       = "10m"
    scale_down_unneeded_time         = "10m"
    estimator                        = "binpacking"
    expander                         = "random"
    ignore_daemonsets_utilization    = true
    balance_similar_node_groups      = true
    scale_down_utilization_threshold = 0.5
    max_graceful_termination_sec     = 600
  }

  # Node pools
  node_pools = {
    system = {
      node_type         = "PRO2-S"
      size              = 3
      min_size          = 2
      max_size          = 5
      autoscaling       = true
      autohealing       = true
      container_runtime = "containerd"
      tags              = ["pool:system", "critical:true"]
      upgrade_policy = {
        max_unavailable = 1
        max_surge       = 0
      }
    }

    workers = {
      node_type         = "PRO2-M"
      size              = 2
      min_size          = 1
      max_size          = 10
      autoscaling       = true
      autohealing       = true
      container_runtime = "containerd"
      tags              = ["pool:workers"]
      upgrade_policy = {
        max_unavailable = 1
        max_surge       = 2
      }
    }

    spot = {
      node_type         = "DEV1-L"
      size              = 0
      min_size          = 0
      max_size          = 20
      autoscaling       = true
      autohealing       = true
      container_runtime = "containerd"
      tags              = ["pool:spot", "preemptible:true"]
    }
  }
}
