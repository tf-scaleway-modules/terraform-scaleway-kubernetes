## Context

The module manages `scaleway_k8s_cluster.this`, `scaleway_k8s_pool.this` (for_each over `node_pools`), `scaleway_k8s_acl.this` (count 0/1) and reads `data.scaleway_account_project.this`. Provider floor is already `~> 2.89` (2.89.0, 2026-10-27, latest on both registries; 2.90.0 is tagged but unpublished and only touches an ephemeral IAM resource this module does not use). The 2.89.0 schema (`/tmp/scw-schema/schema-2.89.0.json`) was diffed against the module: no argument used is deprecated; unexposed arguments are `pod_cidr`, `service_cidr`, `service_dns_ip` (cluster), `security_group_id` (pool) and the `timeouts` blocks; `scaleway_k8s_acl` is fully covered; `data.scaleway_k8s_version` is the only other k8s data source. Motivation: see proposal.md.

Standards: `terraform-versioning`, `terraform-providers`, `terraform-variables`, `terraform-outputs`, `terraform-testing`, `terraform-security`, `quality-simplicity`, `quality-security`.

## Goals / Non-Goals

**Goals:** align with the cross-module conventions (`project_id`, tags merge, objects with `optional()`), remove redundant surface, adopt the CIDR and security-group features, keep an empty second plan for unchanged infrastructure.

**Non-Goals:** see the Deferred/rejected table in proposal.md (private network optional, ephemeral kubeconfig, timeouts, version data source, autoscaler defaults, destructive default flip, public-gateway check, ACL `for_each`).

## Decisions

### D1. `project_id` replaces `organization_id` + `project_name` (`scaleway_k8s_cluster.project_id`, Optional+Computed)
`project_id = var.project_id`, UUID validation, `null` = provider default project. `data.tf` is deleted. `organization_id` stays as an output only (cluster computed attribute); IAM is not used, so no organization input remains.
- No perpetual diff: `project_id` is Optional+Computed; `null` keeps state. A consumer whose project differs from the provider default must set it, otherwise Terraform would plan a replacement (`project_id` is ForceNew); the README upgrade section tells them to compare with the `project_id` output before applying.
- Alternative: keep `project_name`. Rejected: an API read per plan and divergent from sibling modules.

### D2. `network_cidrs` (`pod_cidr`, `service_cidr`, `service_dns_ip`, 2.61.0)
Object `optional(string)` members, default `{}`, each sent as the member (`null` when unset). Validations: `can(cidrhost(x, 0))` for pod and service, which also accepts a bare IP, so the check additionally requires a `/` in the value; for the DNS IP `can(cidrhost("${ip}/32", 0))` with no `/` in the value. Messages name the expected form.
- Perpetual diff: Optional+Computed, `null` keeps what the server chose. State migration: in place for every existing cluster (no change planned). Setting a value on an existing cluster, or changing it, replaces the cluster (ForceNew, documented in the variable description and README); the value cannot be unset once custom.
- Alternative: three flat variables. Rejected: one coherent object (`terraform-variables`).

### D3. Pool `security_group_id` (2.57.0, editable in place since 2.67.1)
Optional string passed through. Optional+Computed: `null` keeps the Scaleway-managed group, so unchanged pools show no diff. No format validation (zonal ID form is not documented by the provider; a regex could reject valid values). The README warns that a custom group must keep node registration traffic open; `quality-security` favours the managed default, hence opt-in.
- Alternative: keep rejecting. Overturned: the 2.67.1 in-place edit removes the replacement risk that justified the rejection.

### D4. Root volume enum
Add `sbs_5k`, `sbs_15k` to the allowed list (Scaleway block-storage root volumes). The provider takes any string, so the module list is the only guard; the apply group verifies a real pool with `sbs_15k` before release. If the API rejects it, the task is dropped and the proposal row removed.

### D5. Pool region removed, tags merged
`region = scaleway_k8s_cluster.this.region` on the pool (the pool region always had to equal the cluster's). `tags = distinct(concat(var.tags, each.value.tags))` (order: module tags first). Not a state-address change; a pool with non-empty tags gets one in-place tag update at the first apply after upgrade. Pool with both empty: no change. `distinct` keeps the plan stable when a tag is in both lists.

### D6. Outputs
- `kubeconfig` = `try(scaleway_k8s_cluster.this.kubeconfig[0], null)` (sensitive); `kubeconfig_file = try(kubeconfig.config_file, null)`; `kubernetes_provider_config` unchanged. Removed: `kubeconfig_host` (= `apiserver_url`), `kubeconfig_cluster_ca_certificate`, `kubeconfig_token` (both in `kubernetes_provider_config`), `helm_provider_config` (identical alias, already documented as deprecated).
- `node_pools` output adds `security_group_id` per pool and `id`, `private_ips` per node (`[for ip in node.private_ips : ip.address]`).
- `project_id` output reads `scaleway_k8s_cluster.this.project_id`.
- Ephemeral output rejected: the value comes from a managed resource attribute, which cannot be ephemeral; the token remains in state as a sensitive computed attribute (no write-only or ephemeral kubeconfig in 2.89). Documented in the README.

### D7. Exceptions to conventions
- `scaleway_k8s_acl.this` keeps `count` (boolean toggle). `terraform-code-style` prefers `for_each` for multiple resources and uses a ternary (`cond ? 1 : 0`) for a simple condition, so this is compliant and needs no `DEVIATION` comment; `for_each` would need a synthetic key and a `moved` block for no benefit.
- `name` stays the cluster name: the module derives no other names (pool names are the map keys).
- `required_version` stays `>= 1.10.0`: no write-only argument or ephemeral resource is used.
- Autoscaler `optional()` defaults mirror provider defaults on purpose (arguments are not Computed).

## Risks / Trade-offs

- [Wrong `project_id` replaces the cluster] → README step: set it to the `project_id` output; the apply group checks `tofu plan` shows no replacement.
- [Pool tag merge causes updates] → in place, listed in the upgrade section.
- [`sbs_*` unsupported by the API] → verified in the real-account group before release.
- [Removing outputs breaks callers] → major bump, consumer edit per output in the README.
- [Mock provider cannot prove an empty second plan] → reasoning above plus a real-account plan after apply (separate group).

## Migration Plan

No resource address changes, so no `moved` blocks. Per change:

| Change | State impact |
|--------|--------------|
| Data source removed | None (data sources are not migrated) |
| `project_id` null with provider default project | None, empty plan |
| `region` removed from pool | None, same value |
| Tags merged | In place update on pools with tags |
| `network_cidrs` `{}`, `security_group_id` null | None |
| Output renames/removals | None (outputs only) |

1. Consumer upgrades the tag, applies the README edits, runs `tofu init -upgrade && tofu plan`: expect only pool tag updates (if any).
2. Rollback: pin v2.0.0; no state format change.
