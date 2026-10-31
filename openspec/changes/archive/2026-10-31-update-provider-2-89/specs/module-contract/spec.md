## MODIFIED Requirements

### Requirement: Tool and provider version constraints
The module SHALL declare `required_version = ">= 1.10.0"` and the provider `scaleway/scaleway` with version `~> 2.89` in `versions.tf`.

#### Scenario: Supported toolchain
- **WHEN** the module is initialised with OpenTofu or Terraform 1.10.0 or newer and a scaleway provider 2.89.x or newer 2.x
- **THEN** initialisation succeeds

#### Scenario: Old toolchain
- **WHEN** the module is initialised with a version older than 1.10.0
- **THEN** initialisation fails on the `required_version` constraint

#### Scenario: Old provider
- **WHEN** the module is initialised with a scaleway provider older than 2.89.0
- **THEN** initialisation fails on the provider constraint

### Requirement: Optional inputs and defaults
The module SHALL default `project_name` to `"default"`, `type` to `"kapsule"`, `cni` to `"cilium"`, `delete_additional_resources` to `false`, `tags`, `feature_gates`, `admission_plugins` and `apiserver_cert_sans` to `[]`, `auto_upgrade` to `{}`, `node_pools` to `{}`, and `description`, `region`, `upgrade_pools`, `autoscaler_config`, `oidc_config` and `api_server_acl` to `null`.

#### Scenario: Defaults applied
- **WHEN** only the required inputs and one node pool are given
- **THEN** the cluster uses type `kapsule`, CNI `cilium`, no tags, and `delete_additional_resources = false`, and no API server ACL is created

### Requirement: Output set
The module SHALL expose these outputs: `id`, `srn`, `name`, `status`, `version`, `upgrade_available`, `type`, `cni`, `region`, `project_id`, `organization_id`, `tags`, `created_at`, `updated_at`, `apiserver_url`, `wildcard_dns`, `kubeconfig`, `kubeconfig_file`, `kubeconfig_host`, `kubeconfig_cluster_ca_certificate`, `kubeconfig_token`, `node_pools`, `node_pool_ids`, `node_pool_versions`, `kubernetes_provider_config` and `helm_provider_config`. Every output SHALL have a description.

#### Scenario: Cluster identity outputs
- **WHEN** the cluster is applied
- **THEN** `id`, `srn`, `name`, `version`, `upgrade_available`, `type`, `cni`, `region`, `tags`, `apiserver_url` and `wildcard_dns` reflect the cluster resource, and `project_id` is the ID of the looked-up project
