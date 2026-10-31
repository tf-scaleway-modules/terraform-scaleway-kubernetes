# cluster Specification

## Purpose
Define the Scaleway Kapsule/Multicloud cluster the module creates: its inputs, validations, auto-upgrade, autoscaler and OIDC configuration.

## Requirements

### Requirement: Cluster resource
The module SHALL create one `scaleway_k8s_cluster` named `var.name`, with `description`, `type`, `kubernetes_version` (as `version`), `cni`, `tags`, `region`, `private_network_id` and `delete_additional_resources` taken from the inputs, in the looked-up project.

#### Scenario: Minimal cluster
- **WHEN** `name`, `organization_id`, `kubernetes_version`, `private_network_id` and one node pool are given
- **THEN** one cluster is planned, attached to the private network, with `delete_additional_resources = false`

### Requirement: Cluster name validation
The module SHALL reject a `name` that does not start with a lowercase letter, contains characters other than lowercase letters, digits and hyphens, or is longer than 63 characters.

#### Scenario: Invalid cluster name
- **WHEN** `name = "Prod_Cluster"`
- **THEN** planning fails with "Cluster name must start with a letter, contain only lowercase letters, numbers, and hyphens, and be at most 63 characters."

### Requirement: Cluster type validation
The module SHALL accept `type` only from `kapsule`, `multicloud`, `kapsule-dedicated-4`, `kapsule-dedicated-8`, `kapsule-dedicated-16`, `multicloud-dedicated-4`, `multicloud-dedicated-8` and `multicloud-dedicated-16`.

#### Scenario: Unknown cluster type
- **WHEN** `type = "kapsule-dedicated-32"`
- **THEN** planning fails with "Cluster type must be one of: kapsule, multicloud, kapsule-dedicated-4/8/16, multicloud-dedicated-4/8/16."

### Requirement: Kubernetes version validation
The module SHALL accept `kubernetes_version` only in the form `X.Y` or `X.Y.Z`.

#### Scenario: Invalid version format
- **WHEN** `kubernetes_version = "v1.31"`
- **THEN** planning fails with "Kubernetes version must be in format 'X.Y' (for auto-upgrade) or 'X.Y.Z' (fixed version)."

### Requirement: CNI validation
The module SHALL accept `cni` only from `cilium`, `calico`, `weave`, `flannel` and `none`.

#### Scenario: Unknown CNI
- **WHEN** `cni = "kube-router"`
- **THEN** planning fails with "CNI must be one of: cilium, calico, weave, flannel, none."

### Requirement: Region validation
The module SHALL accept `region` only as `null` (provider region) or one of `fr-par`, `nl-ams`, `pl-waw`.

#### Scenario: Unsupported region
- **WHEN** `region = "us-east"`
- **THEN** planning fails with "Region must be one of: fr-par, nl-ams, pl-waw."

#### Scenario: Region left unset
- **WHEN** `region` is `null`
- **THEN** the validation passes and the provider region is used

### Requirement: Private network ID validation
The module SHALL accept `private_network_id` only in the form `<region>/<uuid>`.

#### Scenario: Missing region prefix
- **WHEN** `private_network_id = "0b1c2d3e-0000-4000-8000-000000000000"`
- **THEN** planning fails with "Private network ID must be in format 'region/uuid' (e.g., 'fr-par/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx')."

### Requirement: Optional cluster lists
The module SHALL pass `feature_gates`, `admission_plugins` and `apiserver_cert_sans` to the cluster only when the list is non-empty, and SHALL send `null` otherwise.

#### Scenario: Empty lists
- **WHEN** `feature_gates`, `admission_plugins` and `apiserver_cert_sans` are `[]`
- **THEN** none of the three arguments is set on the cluster

#### Scenario: Non-empty list
- **WHEN** `admission_plugins = ["AlwaysPullImages"]`
- **THEN** the cluster is planned with that admission plugin

### Requirement: Auto-upgrade configuration
The module SHALL always configure the `auto_upgrade` block from `var.auto_upgrade`, whose defaults are `enabled = false`, `maintenance_window_start_hour = 3` and `maintenance_window_day = "sunday"`.

#### Scenario: Defaults
- **WHEN** `auto_upgrade` is not set
- **THEN** auto-upgrade is disabled with a window on sunday at hour 3

#### Scenario: Invalid start hour
- **WHEN** `auto_upgrade = { maintenance_window_start_hour = 24 }`
- **THEN** planning fails with "Maintenance window start hour must be between 0 and 23."

#### Scenario: Invalid window day
- **WHEN** `auto_upgrade = { maintenance_window_day = "weekend" }`
- **THEN** planning fails with "Maintenance window day must be one of: monday, tuesday, wednesday, thursday, friday, saturday, sunday, any."

### Requirement: Minor version required with auto-upgrade
The cluster SHALL carry a precondition rejecting `auto_upgrade.enabled = true` when `kubernetes_version` is not of the form `X.Y`.

#### Scenario: Auto-upgrade with a patch version
- **WHEN** `auto_upgrade = { enabled = true }` and `kubernetes_version = "1.31.2"`
- **THEN** planning fails with "When auto_upgrade is enabled, kubernetes_version must be a minor version (e.g., '1.31'), not a patch version."

#### Scenario: Auto-upgrade with a minor version
- **WHEN** `auto_upgrade = { enabled = true }` and `kubernetes_version = "1.31"`
- **THEN** the precondition passes

#### Scenario: Auto-upgrade disabled
- **WHEN** `auto_upgrade.enabled = false` and `kubernetes_version = "1.31.2"`
- **THEN** the precondition passes

### Requirement: Pool upgrade coupling
The module SHALL pass `upgrade_pools` to the cluster unchanged; with the default `null` the provider default applies.

#### Scenario: Pools upgraded separately
- **WHEN** `upgrade_pools = false`
- **THEN** the cluster is planned with `upgrade_pools = false`

### Requirement: Autoscaler configuration
The module SHALL add an `autoscaler_config` block only when `var.autoscaler_config` is not `null`.

#### Scenario: Autoscaler not configured
- **WHEN** `autoscaler_config = null`
- **THEN** no `autoscaler_config` block is produced

#### Scenario: Autoscaler with defaults
- **WHEN** `autoscaler_config = {}`
- **THEN** one `autoscaler_config` block is produced with `disable_scale_down = false`, `scale_down_delay_after_add = "10m"`, `scale_down_unneeded_time = "10m"`, `estimator = "binpacking"`, `expander = "random"`, `ignore_daemonsets_utilization = false`, `balance_similar_node_groups = false`, `expendable_pods_priority_cutoff = -10`, `scale_down_utilization_threshold = 0.5` and `max_graceful_termination_sec = 600`; `skip_nodes_with_local_storage` and `log_level` stay unset

#### Scenario: Invalid estimator
- **WHEN** `autoscaler_config = { estimator = "greedy" }`
- **THEN** planning fails with "Estimator must be one of: binpacking, random."

#### Scenario: Invalid expander
- **WHEN** `autoscaler_config = { expander = "cheapest" }`
- **THEN** planning fails with "Expander must be one of: random, most_pods, least_waste, priority, price."

#### Scenario: Invalid utilization threshold
- **WHEN** `autoscaler_config = { scale_down_utilization_threshold = 1.5 }`
- **THEN** planning fails with "Scale down utilization threshold must be between 0 and 1."

#### Scenario: Invalid log level
- **WHEN** `autoscaler_config = { log_level = 5 }`
- **THEN** planning fails with "Autoscaler log_level must be between 0 and 4."

### Requirement: OpenID Connect configuration
The module SHALL add an `open_id_connect_config` block only when `var.oidc_config` is not `null`, mapping `issuer_url`, `client_id`, `username_claim`, `username_prefix`, `groups_claim`, `groups_prefix` and `required_claim`. `issuer_url` and `client_id` are required inside the object.

#### Scenario: OIDC not configured
- **WHEN** `oidc_config = null`
- **THEN** no `open_id_connect_config` block is produced

#### Scenario: Non-HTTPS issuer
- **WHEN** `oidc_config = { issuer_url = "http://idp.example.com", client_id = "k8s" }`
- **THEN** planning fails with "OIDC issuer URL must start with 'https://'."

#### Scenario: Valid OIDC
- **WHEN** `oidc_config = { issuer_url = "https://idp.example.com", client_id = "k8s" }`
- **THEN** one `open_id_connect_config` block is produced

### Requirement: API server access control
The module SHALL create one `scaleway_k8s_acl` for the cluster only when `var.api_server_acl` is not `null`, and SHALL create none otherwise. `api_server_acl` has either `no_ip_allowed = true` (full isolation, default `false`) or a non-empty `rules` list (default `[]`), never both and never neither. Each rule has a `description` and exactly one of `ip` (a CIDR) or `scaleway_ranges = true`. At most one rule SHALL set `scaleway_ranges = true`.

#### Scenario: ACL not configured
- **WHEN** `api_server_acl = null`
- **THEN** no `scaleway_k8s_acl` is planned and the cluster keeps the provider-side default rule

#### Scenario: CIDR allow-list
- **WHEN** `api_server_acl = { rules = [{ ip = "203.0.113.0/24", description = "office" }] }`
- **THEN** one `scaleway_k8s_acl` is planned for the cluster with that single rule

#### Scenario: Full isolation
- **WHEN** `api_server_acl = { no_ip_allowed = true }`
- **THEN** one `scaleway_k8s_acl` is planned with `no_ip_allowed = true` and no rule

#### Scenario: Neither mode chosen
- **WHEN** `api_server_acl = {}`
- **THEN** planning fails with "api_server_acl must set either no_ip_allowed = true or at least one rule, not both and not neither."

#### Scenario: Both modes chosen
- **WHEN** `api_server_acl = { no_ip_allowed = true, rules = [{ ip = "203.0.113.0/24" }] }`
- **THEN** planning fails with the same message

#### Scenario: Rule with both selectors
- **WHEN** a rule sets `ip = "203.0.113.0/24"` and `scaleway_ranges = true`
- **THEN** planning fails with "Each api_server_acl rule must set exactly one of ip or scaleway_ranges = true."

#### Scenario: Rule with no selector
- **WHEN** a rule sets neither `ip` nor `scaleway_ranges`
- **THEN** planning fails with the same message

#### Scenario: Invalid CIDR
- **WHEN** a rule sets `ip = "203.0.113.5"`
- **THEN** planning fails with "api_server_acl rule ip must be a CIDR (e.g. '203.0.113.0/24')."

#### Scenario: Two Scaleway-ranges rules
- **WHEN** two rules set `scaleway_ranges = true`
- **THEN** planning fails with "api_server_acl may contain at most one rule with scaleway_ranges = true."

### Requirement: World-open ACL warning
A `check` SHALL warn, without failing, when an `api_server_acl` rule allows `0.0.0.0/0` or `::/0`, because it restricts nothing.

#### Scenario: World-open rule
- **WHEN** `api_server_acl = { rules = [{ ip = "0.0.0.0/0" }] }`
- **THEN** the check warns "api_server_acl contains a world-open rule (0.0.0.0/0 or ::/0); it does not restrict API server access."

#### Scenario: Restricted rule
- **WHEN** every rule is a narrower CIDR or `scaleway_ranges = true`
- **THEN** no warning is raised
