mock_provider "scaleway" {}

override_data {
  target = data.scaleway_account_project.this
  values = {
    id = "11111111-1111-1111-1111-111111111111"
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
