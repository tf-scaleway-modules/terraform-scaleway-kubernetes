mock_provider "scaleway" {}

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

run "outputs_kubeconfig_is_one_object" {
  command = apply

  override_resource {
    target = scaleway_k8s_cluster.this
    values = {
      region = "fr-par"
      kubeconfig = [{
        config_file            = "apiVersion: v1"
        host                   = "https://example.test:6443"
        cluster_ca_certificate = "Y2E="
        token                  = "tok"
      }]
    }
  }

  assert {
    condition     = nonsensitive(output.kubeconfig.host) == "https://example.test:6443" && nonsensitive(output.kubeconfig_file) == "apiVersion: v1"
    error_message = "kubeconfig must be one object and kubeconfig_file its config_file."
  }

  assert {
    condition     = nonsensitive(output.kubernetes_provider_config.cluster_ca_certificate) == "ca"
    error_message = "kubernetes_provider_config must decode the CA certificate."
  }
}
