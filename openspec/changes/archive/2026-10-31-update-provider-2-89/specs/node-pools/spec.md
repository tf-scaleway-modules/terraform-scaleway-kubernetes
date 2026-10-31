## ADDED Requirements

### Requirement: Pool Private Network
The module SHALL accept an optional `private_network_id` per pool, in the form `<region>/<uuid>`, and pass it to the pool. With the default `null` the argument is not sent, the nodes join the cluster's Private Network, and an existing pool is neither changed nor replaced. A pool Private Network SHALL belong to the same VPC as the cluster; the provider enforces this at apply time. Changing the value of an existing pool replaces the pool.

#### Scenario: Default network
- **WHEN** a pool does not set `private_network_id`
- **THEN** the pool is planned without that argument and its nodes use the cluster's Private Network

#### Scenario: Dedicated pool network
- **WHEN** a pool has `private_network_id = "fr-par/22222222-2222-2222-2222-222222222222"`
- **THEN** the pool is planned with that Private Network

#### Scenario: Missing region prefix
- **WHEN** a pool has `private_network_id = "22222222-2222-2222-2222-222222222222"`
- **THEN** planning fails with "Node pool private_network_id must be in format 'region/uuid' (e.g., 'fr-par/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx')."

#### Scenario: Second plan
- **WHEN** the pool has been applied with or without `private_network_id` and the inputs are unchanged
- **THEN** the next plan shows no change

## MODIFIED Requirements

### Requirement: Pool outputs
The module SHALL expose `node_pools` (a map by pool name with `id`, `srn`, `name`, `status`, `version`, `node_type`, `size`, `min_size`, `max_size`, `current_size`, `autoscaling`, `autohealing`, `private_network_id`, `zone`, `region`, `created_at`, `updated_at` and a `nodes` list of `name`, `status`, `public_ip`, `public_ipv6`), `node_pool_ids` and `node_pool_versions`.

#### Scenario: Pool IDs
- **WHEN** pools `default` and `gpu` are applied
- **THEN** `node_pool_ids` has the keys `default` and `gpu` mapped to the pool IDs and `node_pool_versions` maps the same keys to their versions

#### Scenario: Pool network and SRN
- **WHEN** a pool is applied
- **THEN** its `node_pools` entry carries the effective `private_network_id` and the pool `srn`
