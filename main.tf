################################################################################
# Kubernetes Cluster
################################################################################

resource "scaleway_k8s_cluster" "this" {
  name        = var.name
  description = var.description
  type        = var.type
  version     = var.kubernetes_version
  cni         = var.cni
  tags        = var.tags

  region     = var.region
  project_id = data.scaleway_account_project.this.id

  private_network_id          = var.private_network_id
  delete_additional_resources = var.delete_additional_resources

  feature_gates       = var.feature_gates
  admission_plugins   = var.admission_plugins
  apiserver_cert_sans = var.apiserver_cert_sans

  auto_upgrade {
    enable                        = var.auto_upgrade.enabled
    maintenance_window_start_hour = var.auto_upgrade.maintenance_window_start_hour
    maintenance_window_day        = var.auto_upgrade.maintenance_window_day
  }

  dynamic "autoscaler_config" {
    for_each = var.autoscaler_config != null ? [var.autoscaler_config] : []

    content {
      disable_scale_down               = autoscaler_config.value.disable_scale_down
      scale_down_delay_after_add       = autoscaler_config.value.scale_down_delay_after_add
      scale_down_unneeded_time         = autoscaler_config.value.scale_down_unneeded_time
      estimator                        = autoscaler_config.value.estimator
      expander                         = autoscaler_config.value.expander
      ignore_daemonsets_utilization    = autoscaler_config.value.ignore_daemonsets_utilization
      balance_similar_node_groups      = autoscaler_config.value.balance_similar_node_groups
      expendable_pods_priority_cutoff  = autoscaler_config.value.expendable_pods_priority_cutoff
      scale_down_utilization_threshold = autoscaler_config.value.scale_down_utilization_threshold
      max_graceful_termination_sec     = autoscaler_config.value.max_graceful_termination_sec
    }
  }
}

################################################################################
# Node Pools
################################################################################

resource "scaleway_k8s_pool" "this" {
  for_each = var.node_pools

  cluster_id = scaleway_k8s_cluster.this.id

  name              = each.key
  node_type         = each.value.node_type
  size              = each.value.size
  min_size          = each.value.min_size
  max_size          = each.value.max_size
  autoscaling       = each.value.autoscaling
  autohealing       = each.value.autohealing
  container_runtime = each.value.container_runtime
  tags              = each.value.tags

  placement_group_id     = each.value.placement_group_id
  zone                   = each.value.zone
  root_volume_type       = each.value.root_volume_type
  root_volume_size_in_gb = each.value.root_volume_size_in_gb
  wait_for_pool_ready    = each.value.wait_for_pool_ready

  dynamic "upgrade_policy" {
    for_each = each.value.upgrade_policy != null ? [each.value.upgrade_policy] : []

    content {
      max_unavailable = upgrade_policy.value.max_unavailable
      max_surge       = upgrade_policy.value.max_surge
    }
  }
}
