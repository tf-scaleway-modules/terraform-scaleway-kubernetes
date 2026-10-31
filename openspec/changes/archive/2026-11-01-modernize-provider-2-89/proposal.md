## Why

The module (v2.0.0, provider `~> 2.89`) works but carries legacy shape: a project lookup through `organization_id` + `project_name`, a pool-level `region` that can only contradict the cluster, five overlapping kubeconfig outputs plus a documented duplicate (`helm_provider_config`), and no way to set the cluster network CIDRs or a pool security group, which production clusters need (peering without CIDR overlap, node firewalling). Provider 2.89.0 (2026-10-27) was checked against the schema: no argument the module uses is deprecated, so the work is shape, consistency and the missing features below. A major release is allowed, which unblocks the items v2.0.0 rejected or deferred.

## What Changes

### Adopted features

| Item | Resource.argument | Provider | Note |
|------|-------------------|----------|------|
| Cluster network CIDRs: input `network_cidrs = { pod, service, service_dns_ip }` | `scaleway_k8s_cluster.pod_cidr`, `service_cidr`, `service_dns_ip` | 2.61.0 | Deferred in v2.0.0 as niche; now a major allows the object shape. Optional+Computed, `null` = provider default, no diff. ForceNew, cannot be unset once custom (documented) |
| Pool security group: `node_pools[*].security_group_id` | `scaleway_k8s_pool.security_group_id` | 2.57.0 (editable in place 2.67.1) | Rejected in v2.0.0 as risky; adopted opt-in because it is in-place editable since 2.67.1, `null` = Scaleway-managed group, and the README states the group must keep node registration traffic open |
| Root volume types `sbs_5k`, `sbs_15k` accepted next to `l_ssd`, `b_ssd` | `scaleway_k8s_pool.root_volume_type` | current API enum; confirmed at apply (real-account group) | The provider does not enumerate values; the module list was too narrow |
| Node private addresses and ids in `node_pools` output (`nodes[*].id`, `private_ips`) and pool `security_group_id` | pool `nodes[*].private_ips`, `security_group_id` | present in the 2.89.0 schema | With `public_ip_disabled = true` a node has no public address to read |
| Project: single optional `project_id` | `scaleway_k8s_cluster.project_id` | 2.x | Cross-module convention, replaces the lookup |

### Breaking changes

| Change | Consumer edit |
|--------|---------------|
| Input `organization_id` removed | Delete it |
| Input `project_name` removed, `project_id` (string, default `null` = provider default project) added; `data.scaleway_account_project` removed | Pass `project_id = "<uuid>"` if the project is not the provider default. A wrong value would replace the cluster (`project_id` is ForceNew): compare with the `project_id` output first |
| `node_pools[*].region` removed (pool region is the cluster region) | Delete it; a pool region different from the cluster's never worked |
| `node_pools[*].tags` now merged (distinct) with the module `tags` | Expect one in-place tag update per pool if `tags` is set; none if empty |
| Output `kubeconfig` changes from a list of objects to one object (or `null`) | Replace `kubeconfig[0].x` with `kubeconfig.x` |
| Outputs `kubeconfig_host`, `kubeconfig_cluster_ca_certificate`, `kubeconfig_token` removed | Use `apiserver_url` or `kubernetes_provider_config.host`, `.cluster_ca_certificate` (already decoded), `.token` |
| Output `helm_provider_config` removed (identical alias) | Use `kubernetes_provider_config` |
| `required_version`, provider floor | Unchanged (`>= 1.10.0`, `~> 2.89`): nothing adopted needs a newer core |

### Simplifications

| Item | Result |
|------|--------|
| `data.tf` and `data.scaleway_account_project` | Removed, one API read less per plan |
| Pool `kubelet_args` sent as `{}` while `labels`/`user_data` send `null` when empty | All three send `null` when empty, one rule |
| Duplicate kubeconfig outputs | One object (`kubeconfig`), one raw file (`kubeconfig_file`), one provider helper |
| Pool `region` attribute | Dropped, the pool takes `scaleway_k8s_cluster.this.region` |

### Deferred / rejected

| Item | Reason |
|------|--------|
| Make cluster `private_network_id` optional (schema marks it Optional) | Docs: Private Networks are mandatory with Kapsule; ForceNew; keeping it required stays safe |
| Ephemeral / write-only kubeconfig | 2.89 has no ephemeral kubeconfig resource; the credentials are a computed attribute and stay in state, sensitive. An `ephemeral` output cannot carry a resource attribute |
| `timeouts` blocks | Speculative; provider defaults suffice (`wait_for_pool_ready` exists) |
| `data.scaleway_k8s_version` to pick the latest version | `kubernetes_version` is a deliberate pin; automatic selection would upgrade unattended |
| Remove autoscaler defaults mirroring the provider | The block's arguments are Optional without Computed; removing the defaults risks a perpetual diff |
| `delete_additional_resources` default flip | Destructive default change |
| Check for Public Gateway when `public_ip_disabled` | Needs an extra data source and API call per plan |
| `count` → `for_each` for `scaleway_k8s_acl.this` | A boolean toggle: `terraform-code-style` uses `cond ? 1 : 0` for a simple condition; `for_each` would force a `moved` block for no gain |
| `scaleway_k8s_cluster.default_pool`, data sources `scaleway_k8s_cluster`/`_pool` | Not in the 2.89 schema / not applicable to a module that owns the resources |

## Capabilities

### New Capabilities
None.

### Modified Capabilities
- `module-contract`: project input, required/optional inputs, output set, upgrade documentation
- `cluster`: project, network CIDRs
- `node-pools`: region, tags, security group, root volume types, outputs
- `kubeconfig-outputs`: object `kubeconfig`, removed host/CA/token and Helm outputs

## Semver

**Major** (`terraform-versioning`): inputs removed (`organization_id`, `project_name`, pool `region`), outputs removed (`kubeconfig_host`, `kubeconfig_cluster_ca_certificate`, `kubeconfig_token`, `helm_provider_config`), output type change (`kubeconfig`), meaning change (`node_pools[*].tags` merged). Added: input `project_id`, `network_cidrs` (default `{}`), `node_pools[*].security_group_id` (default `null`); `node_pools` output keys and node attributes.

## State

Existing resource addresses are unchanged, so no `moved` block. Nothing new in state except `pod_cidr`/`service_cidr`/`service_dns_ip` (computed, not secret) on the cluster. The kubeconfig token stays in state, sensitive; no write-only counterpart exists in 2.89. No secret-bearing input is added, so `terraform-security` write-only rules do not apply. The removed data source leaves no state.

## Impact

`versions.tf` (unchanged), `data.tf` (deleted), `main.tf`, `variables.tf`, `outputs.tf`, `tests/main.tftest.hcl`, `examples/minimal`, `examples/complete`, README (upgrade section, terraform-docs). Specs: the four existing capabilities. Standards: `terraform-versioning`, `terraform-providers`, `terraform-variables`, `terraform-outputs`, `terraform-testing`, `terraform-security`, `quality-simplicity`, `quality-security`.
