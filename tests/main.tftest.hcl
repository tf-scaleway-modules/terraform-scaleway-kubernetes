mock_provider "scaleway" {}

override_data {
  target = data.scaleway_account_project.this
  values = {
    id = "11111111-1111-1111-1111-111111111111"
  }
}

# The mock provider invents random computed values; the ACL needs a real-looking cluster ID and region.
override_resource {
  target = scaleway_k8s_cluster.this
  values = {
    id     = "fr-par/44444444-4444-4444-4444-444444444444"
    region = "fr-par"
  }
}

variables {
  organization_id    = "11111111-1111-1111-1111-111111111111"
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

run "outputs_expose_identifiers" {
  command = apply

  assert {
    condition     = output.srn != null && output.upgrade_available != null
    error_message = "srn and upgrade_available outputs must exist."
  }

  assert {
    condition     = alltrue([for k in ["srn", "private_network_id"] : contains(keys(output.node_pools["default"]), k)])
    error_message = "node_pools entries must expose srn and private_network_id."
  }
}
