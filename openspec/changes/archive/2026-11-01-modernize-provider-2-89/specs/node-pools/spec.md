## MODIFIED Requirements

### Requirement: Root volume
The module SHALL accept `root_volume_type` only as unset, `l_ssd`, `b_ssd`, `sbs_5k` or `sbs_15k`, and `root_volume_size_in_gb` only as unset or at least 20.

#### Scenario: Invalid volume type
- **WHEN** a pool has `root_volume_type = "nvme"`
- **THEN** planning fails with "Root volume type must be one of: l_ssd, b_ssd, sbs_5k, sbs_15k."

#### Scenario: Block storage type
- **WHEN** a pool has `root_volume_type = "sbs_15k"`
- **THEN** the validation passes

#### Scenario: Volume too small
- **WHEN** a pool has `root_volume_size_in_gb = 10`
- **THEN** planning fails with "Root volume size must be at least 20 GB."

### Requirement: Other pool arguments
The module SHALL pass `placement_group_id`, `zone`, `kubelet_args`, `public_ip_disabled` (default `false`) and `wait_for_pool_ready` (default `true`) to the pool, sending `kubelet_args` as `null` when empty. The pool region SHALL be the cluster region; there is no pool `region` input.

#### Scenario: Wait for readiness by default
- **WHEN** a pool does not set `wait_for_pool_ready`
- **THEN** the pool is planned with `wait_for_pool_ready = true`

#### Scenario: Public IP disabled
- **WHEN** a pool has `public_ip_disabled = true`
- **THEN** the pool is planned with public IPs disabled

#### Scenario: Pool region input
- **WHEN** a pool sets `region`
- **THEN** planning fails because the attribute is not supported

### Requirement: Pool outputs
The module SHALL expose `node_pools` (a map by pool name with `id`, `srn`, `name`, `status`, `version`, `node_type`, `size`, `min_size`, `max_size`, `current_size`, `autoscaling`, `autohealing`, `private_network_id`, `security_group_id`, `zone`, `region`, `created_at`, `updated_at` and a `nodes` list of `id`, `name`, `status`, `public_ip`, `public_ipv6`, `private_ips`), `node_pool_ids` and `node_pool_versions`.

#### Scenario: Pool IDs
- **WHEN** pools `default` and `gpu` are applied
- **THEN** `node_pool_ids` has the keys `default` and `gpu` mapped to the pool IDs and `node_pool_versions` maps the same keys to their versions

#### Scenario: Pool network and SRN
- **WHEN** a pool is applied
- **THEN** its `node_pools` entry carries the effective `private_network_id` and the pool `srn`

#### Scenario: Private-only node
- **WHEN** a pool with `public_ip_disabled = true` is applied
- **THEN** each node entry carries its `private_ips` addresses

## ADDED Requirements

### Requirement: Pool tags
The module SHALL set each pool's tags to the distinct union of the module `tags` and the pool's `tags`.

#### Scenario: Merged tags
- **WHEN** `tags = ["env:prod"]` and a pool has `tags = ["pool:web", "env:prod"]`
- **THEN** the pool is planned with the tags `env:prod` and `pool:web` once each

### Requirement: Pool security group
The module SHALL accept an optional `security_group_id` per pool and pass it to the pool; with `null` it is not sent and the Scaleway-managed group is kept without a plan change. The group must allow Kubernetes node traffic.

#### Scenario: Default group
- **WHEN** a pool does not set `security_group_id`
- **THEN** the pool is planned without that argument and an existing pool shows no change

#### Scenario: Custom group
- **WHEN** a pool has `security_group_id = "fr-par-1/33333333-3333-3333-3333-333333333333"`
- **THEN** the pool is planned with that security group
