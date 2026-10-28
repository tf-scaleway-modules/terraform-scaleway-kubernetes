## MODIFIED Requirements

### Requirement: Autoscaling bounds
The pool SHALL carry a precondition requiring both `min_size` and `max_size` to be set when `autoscaling = true`. `autoscaling` defaults to `false` and `autohealing` to `true`.

#### Scenario: Autoscaling without bounds
- **WHEN** a pool `default` has `autoscaling = true` and no `max_size`
- **THEN** planning fails with "When autoscaling is enabled, both min_size and max_size must be specified for pool 'default'."

#### Scenario: Autoscaling with bounds
- **WHEN** a pool has `autoscaling = true`, `min_size = 1` and `max_size = 5`
- **THEN** the precondition passes

### Requirement: Labels and user data
The module SHALL send pool `labels` and `user_data` only when the map is non-empty, and `null` otherwise. The `user_data` key `cloud-init` is reserved by the provider and SHALL be rejected.

#### Scenario: Labels set
- **WHEN** a pool has `labels = { role = "web" }`
- **THEN** the pool is planned with that label

#### Scenario: Empty maps
- **WHEN** a pool has `labels = {}` and `user_data = {}`
- **THEN** neither argument is set on the pool

#### Scenario: Reserved cloud-init key
- **WHEN** a pool has `user_data = { "cloud-init" = "#cloud-config" }`
- **THEN** planning fails with "Node pool user_data must not use the reserved key 'cloud-init'."

### Requirement: Independent pool upgrades
The module SHALL pass a pool's `version` to the pool, so that with the cluster input `upgrade_pools = false` each pool is upgraded separately by changing `node_pools[*].version`. A `check` SHALL warn, without failing, when a pool sets `version` while `upgrade_pools` is not `false`, because the provider then ignores it.

#### Scenario: Pinned pool version
- **WHEN** `upgrade_pools = false` and a pool has `version = "1.31.2"`
- **THEN** the pool is planned with that version and no warning is raised

#### Scenario: Pool version without decoupling
- **WHEN** `upgrade_pools` is `null` or `true` and a pool has `version = "1.31.2"`
- **THEN** the check warns "node_pools[*].version is only honored when upgrade_pools = false."

### Requirement: Other pool arguments
The module SHALL pass `placement_group_id`, `zone`, `region`, `kubelet_args`, `tags`, `public_ip_disabled` (default `false`) and `wait_for_pool_ready` (default `true`) from the pool entry to the pool.

#### Scenario: Wait for readiness by default
- **WHEN** a pool does not set `wait_for_pool_ready`
- **THEN** the pool is planned with `wait_for_pool_ready = true`

#### Scenario: Public IP disabled
- **WHEN** a pool has `public_ip_disabled = true`
- **THEN** the pool is planned with public IPs disabled

## REMOVED Requirements

### Requirement: Public IP requires a private network
**Reason**: The precondition could never fail: `private_network_id` is required and its validation already rejects null, so the requirement was dead.
**Migration**: None. `public_ip_disabled` still defaults to `false` and is passed to the pool unchanged (see "Other pool arguments").
