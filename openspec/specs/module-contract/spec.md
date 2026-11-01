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
The module SHALL require `name`, `kubernetes_version` and `private_network_id`, which have no default. Every input SHALL have a type and a description.

#### Scenario: Missing required input
- **WHEN** the module is called without `name`
- **THEN** planning fails because the variable is required

#### Scenario: Removed organization input
- **WHEN** a caller still passes `organization_id`
- **THEN** planning fails with an unsupported argument error

### Requirement: Optional inputs and defaults
The module SHALL default `type` to `"kapsule"`, `cni` to `"cilium"`, `delete_additional_resources` to `false`, the list inputs `tags`, `feature_gates`, `admission_plugins` and `apiserver_cert_sans` to `[]`, `auto_upgrade`, `network_cidrs` and `node_pools` to `{}`, and `project_id`, `description`, `region`, `upgrade_pools`, `autoscaler_config`, `oidc_config` and `api_server_acl` to `null`.

#### Scenario: Defaults applied
- **WHEN** only the required inputs and one node pool are given
- **THEN** the cluster uses type `kapsule`, CNI `cilium`, no tags, `delete_additional_resources = false`, the provider default project, and no API server ACL is created

### Requirement: Output set
The module SHALL expose these outputs: `id`, `srn`, `name`, `status`, `version`, `upgrade_available`, `type`, `cni`, `region`, `project_id`, `organization_id`, `tags`, `created_at`, `updated_at`, `apiserver_url`, `wildcard_dns`, `kubeconfig`, `kubeconfig_file`, `kubernetes_provider_config`, `node_pools`, `node_pool_ids` and `node_pool_versions`. Every output SHALL have a description.

#### Scenario: Cluster identity outputs
- **WHEN** the cluster is applied
- **THEN** `id`, `srn`, `name`, `version`, `type`, `cni`, `region`, `tags`, `apiserver_url` and `wildcard_dns` reflect the cluster, and `project_id` and `organization_id` are those of the cluster resource

#### Scenario: Removed outputs
- **WHEN** a caller reads `helm_provider_config`, `kubeconfig_host`, `kubeconfig_cluster_ca_certificate` or `kubeconfig_token`
- **THEN** planning fails because the output does not exist

### Requirement: Project selection
The module SHALL accept an optional `project_id` (UUID) passed to the cluster, and SHALL contain no `scaleway_account_project` data source. With `null` the provider default project is used.

#### Scenario: Default project
- **WHEN** `project_id` is not set
- **THEN** the cluster is planned without a module-chosen project and no project lookup occurs

#### Scenario: Explicit project
- **WHEN** `project_id = "11111111-1111-1111-1111-111111111111"`
- **THEN** the cluster is planned in that project

#### Scenario: Invalid project ID
- **WHEN** `project_id = "default"`
- **THEN** planning fails with "Project ID must be a valid UUID."

### Requirement: Upgrade documentation
The README SHALL contain an "Upgrading from v2 to v3" section listing every breaking change with the edit a consumer makes.

#### Scenario: Section present
- **WHEN** the README is read
- **THEN** each removed input and output, the `kubeconfig` type change and the pool tag merge appear with their edit
