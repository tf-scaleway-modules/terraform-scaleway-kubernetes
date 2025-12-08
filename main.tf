
data "scaleway_account_project" "project" {
  name            = var.project_name
  organization_id = var.organization_id
}
resource "scaleway_k8s_cluster" "cluster" {
  name                        = var.cluster_name
  type                        = var.cluster_type
  description                 = var.cluster_description
  version                     = var.cluster_version
  cni                         = var.cluster_cni
  tags                        = var.cluster_tags
  private_network_id          = var.private_network_id
  delete_additional_resources = var.delete_additional_resources
  feature_gates               = var.cluster_feature_gates
  admission_plugins           = var.cluster_admission_plugins
  apiserver_cert_sans         = var.cluster_apiserver_cert_sans
  region                      = var.cluster_region
  project_id                  = data.scaleway_account_project.project.id
  auto_upgrade {
    enable                        = var.enable_auto_upgrade
    maintenance_window_start_hour = var.maintenance_window_start_hour
    maintenance_window_day        = var.maintenance_window_day
  }

  dynamic "autoscaler_config" {
    for_each = var.enable_autoscaler == true ? [1] : []

    content {
      disable_scale_down               = var.disable_scale_down
      scale_down_delay_after_add       = var.scale_down_delay_after_add
      estimator                        = var.estimator
      expander                         = var.expander
      ignore_daemonsets_utilization    = var.ignore_daemonsets_utilization
      balance_similar_node_groups      = var.balance_similar_node_groups
      expendable_pods_priority_cutoff  = var.expendable_pods_priority_cutoff
      scale_down_utilization_threshold = var.scale_down_utilization_threshold
      max_graceful_termination_sec     = var.max_graceful_termination_sec
    }
  }
}
resource "scaleway_k8s_pool" "pools" {
  for_each = var.node_pools

  cluster_id = scaleway_k8s_cluster.cluster.id

  name                = each.key
  node_type           = each.value.node_type
  size                = each.value.size
  min_size            = lookup(each.value, "min_size", each.value.size)
  max_size            = lookup(each.value, "max_size", each.value.size)
  tags                = lookup(each.value, "tags", each.value.tags)
  placement_group_id  = lookup(each.value, "placement_group_id", null)
  autoscaling         = lookup(each.value, "autoscaling", false)
  autohealing         = lookup(each.value, "autohealing", false)
  container_runtime   = "containerd"
  region              = lookup(each.value, "region", null)
  wait_for_pool_ready = lookup(each.value, "wait_for_pool_ready", false)
  depends_on = [scaleway_k8s_cluster.cluster]
}
