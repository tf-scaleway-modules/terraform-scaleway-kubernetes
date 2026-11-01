mock_provider "scaleway" {}

# The mock provider invents random computed values; the ACL needs a real-looking cluster ID and region.
override_resource {
  target = scaleway_k8s_cluster.this
  values = {
    id     = "fr-par/44444444-4444-4444-4444-444444444444"
    region = "fr-par"
  }
}

variables {
  name               = "test"
  kubernetes_version = "1.31"
  private_network_id = "fr-par/22222222-2222-2222-2222-222222222222"
  node_pools = {
    default = {
      node_type = "PRO2-S"
      size      = 1
    }
  }
}

run "happy_path" {
  command = plan

  assert {
    condition     = scaleway_k8s_pool.this["default"].min_size == 1 && scaleway_k8s_pool.this["default"].max_size == 1
    error_message = "min_size and max_size must fall back to size."
  }
}

run "public_ip_disabled_is_passed" {
  command = plan

  variables {
    node_pools = {
      default = {
        node_type          = "PRO2-S"
        size               = 1
        public_ip_disabled = true
      }
    }
  }

  assert {
    condition     = scaleway_k8s_pool.this["default"].public_ip_disabled
    error_message = "public_ip_disabled must be passed to the pool."
  }
}

run "autoscaling_requires_bounds" {
  command = plan

  variables {
    node_pools = {
      default = {
        node_type   = "PRO2-S"
        size        = 1
        autoscaling = true
      }
    }
  }

  expect_failures = [scaleway_k8s_pool.this["default"]]
}

run "user_data_rejects_cloud_init_key" {
  command = plan

  variables {
    node_pools = {
      default = {
        node_type = "PRO2-S"
        size      = 1
        user_data = { "cloud-init" = "#cloud-config" }
      }
    }
  }

  expect_failures = [var.node_pools]
}

run "pool_version_with_upgrade_pools_false_has_no_warning" {
  command = plan

  variables {
    upgrade_pools = false
    node_pools = {
      default = {
        node_type = "PRO2-S"
        size      = 1
        version   = "1.31.2"
      }
    }
  }
}

run "pool_version_without_decoupling_warns" {
  command = plan

  variables {
    node_pools = {
      default = {
        node_type = "PRO2-S"
        size      = 1
        version   = "1.31.2"
      }
    }
  }

  expect_failures = [check.pool_version_requires_upgrade_pools]
}

run "pool_private_network_is_passed" {
  command = plan

  variables {
    node_pools = {
      default = {
        node_type          = "PRO2-S"
        size               = 1
        private_network_id = "fr-par/33333333-3333-3333-3333-333333333333"
      }
    }
  }

  assert {
    condition     = scaleway_k8s_pool.this["default"].private_network_id == "fr-par/33333333-3333-3333-3333-333333333333"
    error_message = "private_network_id must be passed to the pool."
  }
}

run "pool_private_network_defaults_to_null" {
  command = plan

  # The mock provider fills Optional+Computed arguments with random values, so the
  # unset input is asserted instead of the planned argument it is passed to unchanged.
  assert {
    condition     = try(var.node_pools["default"].private_network_id, null) == null
    error_message = "private_network_id must not be sent when unset."
  }
}

run "pool_private_network_requires_region" {
  command = plan

  variables {
    node_pools = {
      default = {
        node_type          = "PRO2-S"
        size               = 1
        private_network_id = "33333333-3333-3333-3333-333333333333"
      }
    }
  }

  expect_failures = [var.node_pools]
}

run "api_server_acl_unset_creates_nothing" {
  command = plan

  assert {
    condition     = length(scaleway_k8s_acl.this) == 0
    error_message = "No ACL must be planned when api_server_acl is null."
  }
}

run "api_server_acl_cidr_allow_list" {
  command = plan

  variables {
    api_server_acl = {
      rules = [{ ip = "203.0.113.0/24", description = "office" }]
    }
  }

  assert {
    condition     = length(scaleway_k8s_acl.this) == 1 && length(scaleway_k8s_acl.this[0].acl_rules) == 1 && scaleway_k8s_acl.this[0].no_ip_allowed == null
    error_message = "One ACL with a single rule and no no_ip_allowed must be planned."
  }
}

run "api_server_acl_scaleway_ranges" {
  command = plan

  variables {
    api_server_acl = {
      rules = [
        { scaleway_ranges = true, description = "scaleway" },
        { ip = "203.0.113.0/24", description = "office" },
      ]
    }
  }

  assert {
    condition     = length(scaleway_k8s_acl.this[0].acl_rules) == 2
    error_message = "Both rules must be planned."
  }
}

run "api_server_acl_full_isolation" {
  command = plan

  variables {
    api_server_acl = { no_ip_allowed = true }
  }

  assert {
    condition     = scaleway_k8s_acl.this[0].no_ip_allowed == true && length(scaleway_k8s_acl.this[0].acl_rules) == 0
    error_message = "A fully isolated ACL must set no_ip_allowed and no rule."
  }
}

run "api_server_acl_rejects_neither_mode" {
  command = plan

  variables {
    api_server_acl = {}
  }

  expect_failures = [var.api_server_acl]
}

run "api_server_acl_rejects_both_modes" {
  command = plan

  variables {
    api_server_acl = {
      no_ip_allowed = true
      rules         = [{ ip = "203.0.113.0/24" }]
    }
  }

  expect_failures = [var.api_server_acl]
}

run "api_server_acl_rejects_rule_with_both_selectors" {
  command = plan

  variables {
    api_server_acl = {
      rules = [{ ip = "203.0.113.0/24", scaleway_ranges = true }]
    }
  }

  expect_failures = [var.api_server_acl]
}

run "api_server_acl_rejects_rule_without_selector" {
  command = plan

  variables {
    api_server_acl = {
      rules = [{ description = "nothing" }]
    }
  }

  expect_failures = [var.api_server_acl]
}

run "api_server_acl_rejects_invalid_cidr" {
  command = plan

  variables {
    api_server_acl = {
      rules = [{ ip = "203.0.113.5" }]
    }
  }

  expect_failures = [var.api_server_acl]
}

run "api_server_acl_rejects_two_scaleway_ranges_rules" {
  command = plan

  variables {
    api_server_acl = {
      rules = [
        { scaleway_ranges = true, description = "a" },
        { scaleway_ranges = true, description = "b" },
      ]
    }
  }

  expect_failures = [var.api_server_acl]
}

run "api_server_acl_world_open_warns" {
  command = plan

  variables {
    api_server_acl = {
      rules = [{ ip = "0.0.0.0/0", description = "everyone" }]
    }
  }

  expect_failures = [check.api_server_acl_not_open_to_world]
}

run "api_server_acl_restricted_has_no_warning" {
  command = plan

  variables {
    api_server_acl = {
      rules = [{ ip = "203.0.113.0/24", description = "office" }]
    }
  }
}

run "project_id_is_passed" {
  command = plan

  variables {
    project_id = "55555555-5555-5555-5555-555555555555"
  }

  assert {
    condition     = scaleway_k8s_cluster.this.project_id == "55555555-5555-5555-5555-555555555555"
    error_message = "project_id must be passed to the cluster."
  }
}

run "project_id_defaults_to_null" {
  command = plan

  assert {
    condition     = var.project_id == null
    error_message = "project_id must not be sent when unset."
  }
}

run "project_id_rejects_non_uuid" {
  command = plan

  variables {
    project_id = "default"
  }

  expect_failures = [var.project_id]
}

run "network_cidrs_default_sends_nothing" {
  command = plan

  assert {
    condition     = var.network_cidrs.pod == null && var.network_cidrs.service == null && var.network_cidrs.service_dns_ip == null
    error_message = "Unset network_cidrs members must not be sent."
  }
}

run "network_cidrs_are_passed" {
  command = plan

  variables {
    network_cidrs = {
      pod            = "10.244.0.0/16"
      service        = "10.32.0.0/20"
      service_dns_ip = "10.32.0.10"
    }
  }

  assert {
    condition     = scaleway_k8s_cluster.this.pod_cidr == "10.244.0.0/16" && scaleway_k8s_cluster.this.service_cidr == "10.32.0.0/20" && scaleway_k8s_cluster.this.service_dns_ip == "10.32.0.10"
    error_message = "network_cidrs must be passed to the cluster."
  }
}

run "network_cidrs_rejects_bare_ip_pod" {
  command = plan

  variables {
    network_cidrs = { pod = "10.244.0.1" }
  }

  expect_failures = [var.network_cidrs]
}

run "network_cidrs_rejects_cidr_dns_ip" {
  command = plan

  variables {
    network_cidrs = { service_dns_ip = "10.32.0.0/24" }
  }

  expect_failures = [var.network_cidrs]
}

run "pool_region_is_cluster_region" {
  command = plan

  assert {
    condition     = scaleway_k8s_pool.this["default"].region == scaleway_k8s_cluster.this.region
    error_message = "The pool region must be the cluster region."
  }
}

run "pool_tags_are_merged_distinct" {
  command = plan

  variables {
    tags = ["env:prod"]
    node_pools = {
      default = {
        node_type = "PRO2-S"
        size      = 1
        tags      = ["pool:web", "env:prod"]
      }
    }
  }

  assert {
    condition     = length(scaleway_k8s_pool.this["default"].tags) == 2 && contains(scaleway_k8s_pool.this["default"].tags, "env:prod") && contains(scaleway_k8s_pool.this["default"].tags, "pool:web")
    error_message = "Pool tags must be the distinct union of module and pool tags."
  }
}

run "pool_security_group_is_passed" {
  command = plan

  variables {
    node_pools = {
      default = {
        node_type         = "PRO2-S"
        size              = 1
        security_group_id = "fr-par-1/33333333-3333-3333-3333-333333333333"
      }
    }
  }

  assert {
    condition     = scaleway_k8s_pool.this["default"].security_group_id == "fr-par-1/33333333-3333-3333-3333-333333333333"
    error_message = "security_group_id must be passed to the pool."
  }
}

run "pool_security_group_defaults_to_null" {
  command = plan

  assert {
    condition     = try(var.node_pools["default"].security_group_id, null) == null
    error_message = "security_group_id must not be sent when unset."
  }
}

run "root_volume_type_accepts_sbs_15k" {
  command = plan

  variables {
    node_pools = {
      default = {
        node_type        = "PRO2-S"
        size             = 1
        root_volume_type = "sbs_15k"
      }
    }
  }

  assert {
    condition     = scaleway_k8s_pool.this["default"].root_volume_type == "sbs_15k"
    error_message = "sbs_15k must be accepted and passed."
  }
}

run "root_volume_type_rejects_nvme" {
  command = plan

  variables {
    node_pools = {
      default = {
        node_type        = "PRO2-S"
        size             = 1
        root_volume_type = "nvme"
      }
    }
  }

  expect_failures = [var.node_pools]
}

run "pool_kubelet_args_empty_sends_nothing" {
  command = plan

  assert {
    condition     = length(var.node_pools["default"].kubelet_args) == 0
    error_message = "Empty kubelet_args must be sent as null."
  }
}

run "outputs_expose_identifiers" {
  command = apply

  assert {
    condition     = output.srn != null && output.upgrade_available != null
    error_message = "srn and upgrade_available outputs must exist."
  }

  assert {
    condition     = alltrue([for k in ["srn", "private_network_id", "security_group_id"] : contains(keys(output.node_pools["default"]), k)])
    error_message = "node_pools entries must expose srn, private_network_id and security_group_id."
  }

  assert {
    condition     = output.project_id == scaleway_k8s_cluster.this.project_id
    error_message = "project_id must be read from the cluster."
  }
}

run "outputs_kubeconfig_is_null_without_element" {
  command = apply

  assert {
    condition     = output.kubeconfig == null && output.kubeconfig_file == null && output.kubernetes_provider_config.host == null
    error_message = "kubeconfig outputs must be null when the cluster has no kubeconfig element."
  }
}
