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

  feature_gates       = length(var.feature_gates) > 0 ? var.feature_gates : null
  admission_plugins   = length(var.admission_plugins) > 0 ? var.admission_plugins : null
  apiserver_cert_sans = length(var.apiserver_cert_sans) > 0 ? var.apiserver_cert_sans : null

  auto_upgrade {
    enable                        = var.auto_upgrade.enabled
    maintenance_window_start_hour = var.auto_upgrade.maintenance_window_start_hour
    maintenance_window_day        = var.auto_upgrade.maintenance_window_day
  }

  upgrade_pools = var.upgrade_pools

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
      skip_nodes_with_local_storage    = autoscaler_config.value.skip_nodes_with_local_storage
      log_level                        = autoscaler_config.value.log_level
    }
  }

  dynamic "open_id_connect_config" {
    for_each = var.oidc_config != null ? [var.oidc_config] : []

    content {
      issuer_url      = open_id_connect_config.value.issuer_url
      client_id       = open_id_connect_config.value.client_id
      username_claim  = open_id_connect_config.value.username_claim
      username_prefix = open_id_connect_config.value.username_prefix
      groups_claim    = open_id_connect_config.value.groups_claim
      groups_prefix   = open_id_connect_config.value.groups_prefix
      required_claim  = open_id_connect_config.value.required_claim
    }
  }

  lifecycle {
    precondition {
      condition     = var.auto_upgrade.enabled == false || can(regex("^\\d+\\.\\d+$", var.kubernetes_version))
      error_message = "When auto_upgrade is enabled, kubernetes_version must be a minor version (e.g., '1.31'), not a patch version."
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
  min_size          = coalesce(each.value.min_size, each.value.size)
  max_size          = coalesce(each.value.max_size, each.value.size)
  autoscaling       = each.value.autoscaling
  autohealing       = each.value.autohealing
  container_runtime = each.value.container_runtime
  tags              = each.value.tags

  placement_group_id = each.value.placement_group_id
  zone               = each.value.zone
  region             = each.value.region

  root_volume_type       = each.value.root_volume_type
  root_volume_size_in_gb = each.value.root_volume_size_in_gb
  public_ip_disabled     = each.value.public_ip_disabled

  private_network_id  = each.value.private_network_id
  kubelet_args        = each.value.kubelet_args
  wait_for_pool_ready = each.value.wait_for_pool_ready
  version             = each.value.version

  labels    = length(each.value.labels) > 0 ? each.value.labels : null
  user_data = length(each.value.user_data) > 0 ? each.value.user_data : null

  dynamic "taints" {
    for_each = each.value.taints

    content {
      key    = taints.value.key
      value  = taints.value.value
      effect = taints.value.effect
    }
  }

  dynamic "startup_taints" {
    for_each = each.value.startup_taints

    content {
      key    = startup_taints.value.key
      value  = startup_taints.value.value
      effect = startup_taints.value.effect
    }
  }

  dynamic "upgrade_policy" {
    for_each = each.value.upgrade_policy != null ? [each.value.upgrade_policy] : []

    content {
      max_unavailable = upgrade_policy.value.max_unavailable
      max_surge       = upgrade_policy.value.max_surge
    }
  }

  lifecycle {
    precondition {
      condition     = !each.value.autoscaling || (each.value.min_size != null && each.value.max_size != null)
      error_message = "When autoscaling is enabled, both min_size and max_size must be specified for pool '${each.key}'."
    }
  }
}

################################################################################
# API Server Access Control
################################################################################

resource "scaleway_k8s_acl" "this" {
  count = var.api_server_acl != null ? 1 : 0

  cluster_id = scaleway_k8s_cluster.this.id
  region     = scaleway_k8s_cluster.this.region

  # The provider rejects an explicit false next to acl_rules (ExactlyOneOf).
  no_ip_allowed = var.api_server_acl.no_ip_allowed ? true : null

  dynamic "acl_rules" {
    for_each = var.api_server_acl.rules

    content {
      ip              = acl_rules.value.ip
      scaleway_ranges = acl_rules.value.scaleway_ranges ? true : null
      description     = acl_rules.value.description
    }
  }
}

################################################################################
# Checks
################################################################################

check "pool_version_requires_upgrade_pools" {
  assert {
    condition     = var.upgrade_pools == false || alltrue([for v in var.node_pools : v.version == null])
    error_message = "node_pools[*].version is only honored when upgrade_pools = false."
  }
}

check "api_server_acl_not_open_to_world" {
  assert {
    condition     = var.api_server_acl == null || !anytrue([for r in var.api_server_acl.rules : r.ip != null && contains(["0.0.0.0/0", "::/0"], r.ip)])
    error_message = "api_server_acl contains a world-open rule (0.0.0.0/0 or ::/0); it does not restrict API server access."
  }
}
