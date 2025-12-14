################################################################################
# Complete Example - Scaleway Kubernetes Cluster
# Demonstrates all available features and configurations
################################################################################

module "kubernetes" {
  source = "../.."

  # Project
  organization_id = var.organization_id
  project_name    = var.project_name

  # Network
  private_network_id = var.private_network_id

  # Cluster Configuration
  name               = "production-cluster"
  description        = "Production Kubernetes cluster with full configuration"
  type               = "kapsule"
  kubernetes_version = "1.34"
  cni                = "cilium"
  region             = "fr-par"
  tags               = ["env:production", "team:platform", "managed-by:terraform"]

  # Cluster Features
  delete_additional_resources = true
  feature_gates               = []
  admission_plugins           = []
  apiserver_cert_sans         = []

  # Auto Upgrade Configuration
  auto_upgrade = {
    enabled                       = true
    maintenance_window_start_hour = 3
    maintenance_window_day        = "sunday"
  }

  # Cluster Autoscaler Configuration
  autoscaler_config = {
    disable_scale_down               = false
    scale_down_delay_after_add       = "10m"
    scale_down_unneeded_time         = "10m"
    estimator                        = "binpacking"
    expander                         = "least_waste"
    ignore_daemonsets_utilization    = true
    balance_similar_node_groups      = true
    expendable_pods_priority_cutoff  = -10
    scale_down_utilization_threshold = 0.5
    max_graceful_termination_sec     = 600
  }

  # OpenID Connect Configuration (optional)
  # oidc_config = {
  #   issuer_url      = "https://accounts.google.com"
  #   client_id       = "your-client-id"
  #   username_claim  = "email"
  #   groups_claim    = ["groups"]
  # }

  # Node Pools
  node_pools = {
    # System pool for cluster components
    system = {
      node_type              = "PRO2-S"
      size                   = 3
      min_size               = 2
      max_size               = 5
      autoscaling            = true
      autohealing            = true
      container_runtime      = "containerd"
      zone                   = "fr-par-1"
      root_volume_type       = "b_ssd"
      root_volume_size_in_gb = 50
      public_ip_disabled     = false
      wait_for_pool_ready    = true
      tags                   = ["pool:system", "critical:true"]

      upgrade_policy = {
        max_unavailable = 1
        max_surge       = 0
      }
    }

    # Worker pool for application workloads
    workers = {
      node_type              = "PRO2-M"
      size                   = 2
      min_size               = 1
      max_size               = 10
      autoscaling            = true
      autohealing            = true
      container_runtime      = "containerd"
      zone                   = "fr-par-1"
      root_volume_type       = "b_ssd"
      root_volume_size_in_gb = 100
      public_ip_disabled     = false
      wait_for_pool_ready    = true
      tags                   = ["pool:workers"]

      upgrade_policy = {
        max_unavailable = 1
        max_surge       = 2
      }
    }

    # Batch pool for batch workloads
    batch = {
      node_type              = "DEV1-L"
      size                   = 1
      min_size               = 1
      max_size               = 20
      autoscaling            = true
      autohealing            = true
      container_runtime      = "containerd"
      zone                   = "fr-par-2"
      root_volume_size_in_gb = 50
      public_ip_disabled     = false
      wait_for_pool_ready    = true
      tags                   = ["pool:batch"]
    }
  }
}

################################################################################
# Kubernetes Provider Configuration (for deploying resources to the cluster)
################################################################################

provider "kubernetes" {
  host                   = module.kubernetes.kubeconfig_host
  cluster_ca_certificate = base64decode(module.kubernetes.kubeconfig_cluster_ca_certificate)
  token                  = module.kubernetes.kubeconfig_token
}

# Note: Helm provider configuration should be in a separate file or use the kubernetes provider
# provider "helm" {
#   kubernetes {
#     host                   = module.kubernetes.kubeconfig_host
#     cluster_ca_certificate = base64decode(module.kubernetes.kubeconfig_cluster_ca_certificate)
#     token                  = module.kubernetes.kubeconfig_token
#   }
# }
