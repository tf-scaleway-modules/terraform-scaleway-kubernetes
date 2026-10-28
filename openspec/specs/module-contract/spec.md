# module-contract Specification

## Purpose
Define the module's version constraints, required and optional inputs, project lookup and output set.

## Requirements

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

### Requirement: No provider or backend configuration
The module SHALL NOT contain `provider` or `backend` blocks; the caller configures the Scaleway provider and the state backend.

#### Scenario: Caller owns the provider
- **WHEN** the module is called from a root module that configures the `scaleway` provider
- **THEN** the module uses that provider configuration without defining its own

### Requirement: Required inputs
The module SHALL require `organization_id`, `name`, `kubernetes_version` and `private_network_id`, which have no default. Every input SHALL have a type and a description.

#### Scenario: Missing required input
- **WHEN** the module is called without `name`
- **THEN** planning fails because the variable is required

### Requirement: Optional inputs and defaults
The module SHALL default `project_name` to `"default"`, `type` to `"kapsule"`, `cni` to `"cilium"`, `delete_additional_resources` to `false`, `tags`, `feature_gates`, `admission_plugins` and `apiserver_cert_sans` to `[]`, `auto_upgrade` to `{}`, `node_pools` to `{}`, and `description`, `region`, `upgrade_pools`, `autoscaler_config`, `oidc_config` and `api_server_acl` to `null`.

#### Scenario: Defaults applied
- **WHEN** only the required inputs and one node pool are given
- **THEN** the cluster uses type `kapsule`, CNI `cilium`, no tags, and `delete_additional_resources = false`, and no API server ACL is created

### Requirement: Organization ID format
The module SHALL reject an `organization_id` that is not a lowercase hexadecimal UUID.

#### Scenario: Invalid organization ID
- **WHEN** `organization_id = "not-a-uuid"`
- **THEN** planning fails with "Organization ID must be a valid UUID."

### Requirement: Project lookup
The module SHALL look up the Scaleway project by `project_name` within `organization_id` through the `scaleway_account_project` data source and create the cluster in that project.

#### Scenario: Default project
- **WHEN** `project_name` is not set
- **THEN** the project named `default` of the organization is used

### Requirement: Output set
The module SHALL expose these outputs: `id`, `srn`, `name`, `status`, `version`, `upgrade_available`, `type`, `cni`, `region`, `project_id`, `organization_id`, `tags`, `created_at`, `updated_at`, `apiserver_url`, `wildcard_dns`, `kubeconfig`, `kubeconfig_file`, `kubeconfig_host`, `kubeconfig_cluster_ca_certificate`, `kubeconfig_token`, `node_pools`, `node_pool_ids`, `node_pool_versions`, `kubernetes_provider_config` and `helm_provider_config`. Every output SHALL have a description.

#### Scenario: Cluster identity outputs
- **WHEN** the cluster is applied
- **THEN** `id`, `srn`, `name`, `version`, `upgrade_available`, `type`, `cni`, `region`, `tags`, `apiserver_url` and `wildcard_dns` reflect the cluster resource, and `project_id` is the ID of the looked-up project
