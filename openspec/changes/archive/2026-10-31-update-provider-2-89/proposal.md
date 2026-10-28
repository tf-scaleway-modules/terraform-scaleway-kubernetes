## Why

Scaleway provider 2.89.0 (2026-10-27) is out and the module pins `~> 2.86`. A gap analysis of `scaleway_k8s_cluster`, `scaleway_k8s_pool` and `scaleway_account_project` between 2.86.0 and 2.89.0, plus the arguments and resources the module does not expose yet, found one new provider feature worth adopting (pool Private Network, 2.87.0) and two older, security-relevant gaps (API server allow-list, missing identifiers in outputs).

## What Changes

| # | Item | Provider | Decision | Breaking |
|---|------|----------|----------|----------|
| 1 | `node_pools[*].private_network_id` attaches a pool's nodes to a different Private Network of the cluster's VPC (default `null` = cluster network) | `scaleway_k8s_pool.private_network_id`, **2.87.0** | Adopt, opt-in per pool | No |
| 2 | `api_server_acl` input creating `scaleway_k8s_acl` (allow-list of CIDRs, Scaleway ranges, or full isolation) with a `check` that warns on a world-open rule | `scaleway_k8s_acl`, available in 2.86.0 | Adopt, opt-in (`null` = no resource, no change) | No |
| 3 | New outputs `srn` and `upgrade_available`; `node_pools` output gains `private_network_id` and `srn` per pool | cluster/pool `srn`, cluster `upgrade_available`, available in 2.86.0 | Adopt | No |
| 4 | `versions.tf`: `~> 2.86` becomes `~> 2.89` | needed by item 1 (2.87.0) | Floor raised | **Yes** |

Deferred and rejected items are listed in `design.md` (Non-goals).

Semver: **major**. Items 1 to 3 alone would be minor (new optional inputs with `null` defaults, new outputs, new output keys). Item 1 uses an argument that does not exist in provider 2.86.0, so the provider floor is raised to `~> 2.89` and `terraform-versioning` makes a raised floor a major bump. The floor is `2.89` rather than `2.87` for consistency with the sibling modules. The commit body and README carry the reason. Consumers whose lock file holds 2.86.x to 2.88.x run `tofu init -upgrade`.

Inputs and outputs whose type, default or meaning changes: none. Added: input `api_server_acl` (default `null`), per-pool attribute `private_network_id` (default `null`), outputs `srn` and `upgrade_available`, keys `private_network_id` and `srn` in each `node_pools` entry.

State: existing pools keep their state; the provider stores the effective Private Network in `private_network_id` (Optional + Computed), so `null` plans no change and no replacement. A pool whose `private_network_id` is later set to a different value is replaced (provider `ForceNew`). `scaleway_k8s_acl` is added to state only when `api_server_acl` is set; it holds CIDRs and descriptions, no secret. No secret-bearing input is added, so the write-only rule of `terraform-security` does not apply; the module has no `SECURITY.md`, so nothing is added there, and the README gains a lock-out note.

## Capabilities

### New Capabilities
None.

### Modified Capabilities
- `module-contract`: provider constraint `~> 2.89`, new optional-input defaults, new outputs in the output set
- `cluster`: optional API server access control (`api_server_acl`) with validations and a world-open warning
- `node-pools`: per-pool `private_network_id` with validation, pool outputs extended

## Impact

`versions.tf`, `main.tf` (pool argument, `scaleway_k8s_acl.this`, one `check`), `variables.tf` (`api_server_acl`, pool attribute, validations), `outputs.tf`, `tests/main.tftest.hcl`, `examples/complete`, README (terraform-docs block, provider badge, upgrade note). `data.tf` is unchanged. No change to `examples/minimal`.
