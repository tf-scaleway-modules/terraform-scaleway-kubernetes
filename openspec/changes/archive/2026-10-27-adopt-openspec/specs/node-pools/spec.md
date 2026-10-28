## ADDED Requirements

### Requirement: One pool per map entry
The module SHALL create one `scaleway_k8s_pool` per entry of `var.node_pools` in the cluster, named by the map key, with `node_type` and `size` from the entry. `node_pools` SHALL contain at least one entry.

#### Scenario: Two pools
- **WHEN** `node_pools` has keys `default` and `gpu`
- **THEN** two pools named `default` and `gpu` are planned in the cluster

#### Scenario: No pool
- **WHEN** `node_pools = {}`
- **THEN** planning fails with "At least one node pool must be defined."

### Requirement: Pool name validation
The module SHALL reject a pool key that does not start with a lowercase letter, contains characters other than lowercase letters, digits and hyphens, or exceeds 63 characters.

#### Scenario: Invalid pool name
- **WHEN** a pool key is `GPU_pool`
- **THEN** planning fails with "Node pool names must start with a letter, contain only lowercase letters, numbers, and hyphens, and be at most 63 characters."

### Requirement: Pool sizing
The module SHALL set `min_size` and `max_size` of a pool to the given values, falling back to `size` when they are unset. `size` SHALL be at least 1, `min_size` and `max_size` SHALL be at least 1 when set, and `min_size` SHALL NOT exceed `max_size` when both are set.

#### Scenario: Sizes default to size
- **WHEN** a pool has `size = 3` and no `min_size` or `max_size`
- **THEN** the pool is planned with `min_size = 3` and `max_size = 3`

#### Scenario: Size below one
- **WHEN** a pool has `size = 0`
- **THEN** planning fails with "Node pool size must be at least 1."

#### Scenario: min_size below one
- **WHEN** a pool has `min_size = 0`
- **THEN** planning fails with "Node pool min_size must be at least 1."

#### Scenario: max_size below one
- **WHEN** a pool has `max_size = 0`
- **THEN** planning fails with "Node pool max_size must be at least 1."

#### Scenario: Inverted bounds
- **WHEN** a pool has `min_size = 5` and `max_size = 2`
- **THEN** planning fails with "Node pool min_size must be less than or equal to max_size."

### Requirement: Autoscaling bounds
The pool SHALL carry a precondition requiring both `min_size` and `max_size` to be set when `autoscaling = true`. `autoscaling` defaults to `false` and `autohealing` to `true`.

#### Scenario: Autoscaling without bounds
- **WHEN** a pool `default` has `autoscaling = true` and no `max_size`
- **THEN** planning fails with "When autoscaling is enabled, both min_size and max_size should be specified for pool 'default'."

#### Scenario: Autoscaling with bounds
- **WHEN** a pool has `autoscaling = true`, `min_size = 1` and `max_size = 5`
- **THEN** the precondition passes

### Requirement: Container runtime
The module SHALL accept `container_runtime` only as `containerd` (default) or `crio`.

#### Scenario: Unsupported runtime
- **WHEN** a pool has `container_runtime = "docker"`
- **THEN** planning fails with "Container runtime must be one of: containerd, crio."

### Requirement: Root volume
The module SHALL accept `root_volume_type` only as unset, `l_ssd` or `b_ssd`, and `root_volume_size_in_gb` only as unset or at least 20.

#### Scenario: Invalid volume type
- **WHEN** a pool has `root_volume_type = "nvme"`
- **THEN** planning fails with "Root volume type must be one of: l_ssd, b_ssd."

#### Scenario: Volume too small
- **WHEN** a pool has `root_volume_size_in_gb = 10`
- **THEN** planning fails with "Root volume size must be at least 20 GB."

### Requirement: Zone
The module SHALL accept a pool `zone` only as unset or in the form `<region>-<1..3>`, for example `fr-par-1`.

#### Scenario: Invalid zone
- **WHEN** a pool has `zone = "fr-par"`
- **THEN** planning fails with "Zone must be in format 'region-az' (e.g., 'fr-par-1', 'nl-ams-2')."

### Requirement: Labels and user data
The module SHALL send pool `labels` and `user_data` only when the map is non-empty, and `null` otherwise.

#### Scenario: Labels set
- **WHEN** a pool has `labels = { role = "web" }`
- **THEN** the pool is planned with that label

#### Scenario: Empty maps
- **WHEN** a pool has `labels = {}` and `user_data = {}`
- **THEN** neither argument is set on the pool

### Requirement: Taints and startup taints
The module SHALL create one `taints` block per entry of a pool's `taints` and one `startup_taints` block per entry of `startup_taints`, each with `key`, `value` and `effect`. The effect of every taint and startup taint SHALL be `NoSchedule`, `PreferNoSchedule` or `NoExecute`.

#### Scenario: Taint produced
- **WHEN** a pool has `taints = [{ key = "dedicated", value = "gpu", effect = "NoSchedule" }]`
- **THEN** the pool has one `taints` block with those values

#### Scenario: Invalid taint effect
- **WHEN** a pool has `taints = [{ key = "k", value = "v", effect = "Evict" }]`
- **THEN** planning fails with "Taint effect must be one of: NoSchedule, PreferNoSchedule, NoExecute."

#### Scenario: Invalid startup taint effect
- **WHEN** a pool has `startup_taints = [{ key = "k", value = "v", effect = "Evict" }]`
- **THEN** planning fails with the same taint effect error

### Requirement: Pool upgrade policy
The module SHALL add an `upgrade_policy` block to a pool only when the pool's `upgrade_policy` is set, with defaults `max_unavailable = 1` and `max_surge = 0`.

#### Scenario: No upgrade policy
- **WHEN** a pool does not set `upgrade_policy`
- **THEN** no `upgrade_policy` block is produced

#### Scenario: Upgrade policy defaults
- **WHEN** a pool has `upgrade_policy = {}`
- **THEN** one block with `max_unavailable = 1` and `max_surge = 0` is produced

### Requirement: Independent pool upgrades
The module SHALL pass a pool's `version` to the pool, so that with the cluster input `upgrade_pools = false` each pool is upgraded separately by changing `node_pools[*].version`.

#### Scenario: Pinned pool version
- **WHEN** `upgrade_pools = false` and a pool has `version = "1.31.2"`
- **THEN** the pool is planned with that version

### Requirement: Public IP requires a private network
The pool SHALL carry a precondition that `public_ip_disabled` is only accepted when `private_network_id` is not `null`. `public_ip_disabled` defaults to `false`.

#### Scenario: Public IP disabled with a private network
- **WHEN** a pool has `public_ip_disabled = true` and `private_network_id` is set
- **THEN** the pool is planned with public IPs disabled

### Requirement: Other pool arguments
The module SHALL pass `placement_group_id`, `zone`, `region`, `kubelet_args`, `tags` and `wait_for_pool_ready` (default `true`) from the pool entry to the pool.

#### Scenario: Wait for readiness by default
- **WHEN** a pool does not set `wait_for_pool_ready`
- **THEN** the pool is planned with `wait_for_pool_ready = true`

### Requirement: Pool outputs
The module SHALL expose `node_pools` (a map by pool name with `id`, `name`, `status`, `version`, `node_type`, `size`, `min_size`, `max_size`, `current_size`, `autoscaling`, `autohealing`, `zone`, `region`, `created_at`, `updated_at` and a `nodes` list of `name`, `status`, `public_ip`, `public_ipv6`), `node_pool_ids` and `node_pool_versions`.

#### Scenario: Pool IDs
- **WHEN** pools `default` and `gpu` are applied
- **THEN** `node_pool_ids` has the keys `default` and `gpu` mapped to the pool IDs and `node_pool_versions` maps the same keys to their versions
