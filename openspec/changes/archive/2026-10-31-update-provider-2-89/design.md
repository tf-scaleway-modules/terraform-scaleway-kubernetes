## Context

Observed state: the module manages `scaleway_k8s_cluster.this`, `scaleway_k8s_pool.this` (for_each over `node_pools`) and reads `data.scaleway_account_project.this`; `versions.tf` pins `~> 2.86`. Provider docs of v2.86.0 and v2.89.0 were diffed for these resources. Between the two tags the only change to a resource the module manages is `scaleway_k8s_pool.private_network_id` (2.87.0); `scaleway_account_project` gained a computed `srn` (2.87.0, unused). The remainder of this change comes from comparing every 2.89.0 argument and attribute against what the module exposes. Motivation: see proposal.md.

Standards applied: `terraform-versioning` (raised floor = major), `terraform-providers` (raised floor scenario, optional features gated by a `null`-able input), `terraform-variables` (declaration shape, `null` means provider default, validation messages name the accepted values, enum/pattern validations tested with `expect_failures`), `terraform-testing` (mock-provider plan tests, a run per validation and per check), `terraform-security` (guardrails as `check`, secret handling), `quality-simplicity` and `quality-security` (opt-in, no new abstraction, narrow access by default).

## Goals / Non-Goals

**Goals:**
- Adopt the 2.87.0 pool Private Network argument without touching existing pools.
- Let consumers restrict the API server from the module, with a plan-time warning for a rule that restricts nothing.
- Expose identifiers (`srn`, `upgrade_available`, pool `private_network_id`) that consumers otherwise have to look up.

**Non-Goals (considered, deferred or rejected):**
- `scaleway_k8s_cluster.pod_cidr`, `service_cidr`, `service_dns_ip` (exist in 2.86.0): niche, force replacement of the cluster, cannot be unset once set; deferred until a consumer asks.
- `scaleway_k8s_pool.security_group_id` (exists in 2.86.0): Kapsule nodes need provider-managed rules; a wrong group breaks node registration, so it is not worth a low-confidence input.
- `scaleway_k8s_pool.user_data` is already exposed. The `cloud-init` key is reserved and the provider has no `cloud_init` argument in the pool schema, so nothing to add. `user_data` is not `sensitive` and has no write-only variant in the provider, so cloud-init content lands in state; callers must not put secrets in it (README note, no code change).
- `data.scaleway_k8s_version.available_container_runtimes` deprecation (2.84.0): the module does not use that data source.
- `data.scaleway_account_project.srn` (2.87.0): no consumer need; it would add an output with no use case.
- `delete_additional_resources` default: stays `false`; flipping it would be a destructive default change.
- Data sources `scaleway_k8s_cluster`/`scaleway_k8s_pool`, and cluster `default_pool` (deprecated): not applicable to a module that owns the resources.
- Integration fixture: none exists in the module; applying against the account is out of scope without a request.

## Decisions

### D1. Pool `private_network_id` (`scaleway_k8s_pool.private_network_id`, 2.87.0)
Added as `optional(string)` in the `node_pools` object, passed straight through (`private_network_id = each.value.private_network_id`).
- **No perpetual diff**: in provider source the attribute is `Optional + Computed + ForceNew`. With `null` in configuration Terraform keeps the stored value, so existing pools (whose state holds the cluster's network after refresh) plan no change. The provider has no diff-suppress for this attribute and stores the value as `<region>/<uuid>`; a bare UUID in configuration would therefore differ from state and force replacement on every plan. A validation on the pool attribute requires the `<region>/<uuid>` form (the same regex as the cluster's `private_network_id`), so the config always matches state.
- **State migration**: in place for every existing pool (no change planned). Setting it on an existing pool to a value different from the effective one replaces the pool (provider `ForceNew`); the README upgrade note says so and recommends a new pool name plus drain. No `moved` block: no address changes.
- Same-VPC rule is checked by the API at apply time; it cannot be checked at plan time without a data source, which would add an API call per pool for little value.
- Alternative rejected: a module-level default network for all pools. It duplicates the cluster's input and invites accidental replacement of every pool.

### D2. API server ACL (`scaleway_k8s_acl.this`, resource available before 2.86.0)
New resource `scaleway_k8s_acl.this` with `count = var.api_server_acl != null ? 1 : 0` (feature flag through a `null`-able input, `terraform-providers`), `cluster_id = scaleway_k8s_cluster.this.id`, `region = scaleway_k8s_cluster.this.region`.
- Input shape: `object({ no_ip_allowed = optional(bool, false), rules = optional(list(object({ ip = optional(string), scaleway_ranges = optional(bool, false), description = optional(string) })), []) })`, default `null`. The `optional` defaults here are the neutral values, not invented provider values.
- The provider declares `no_ip_allowed` and `acl_rules` as ExactlyOneOf and `no_ip_allowed` defaults to `false`; an explicit `false` next to rules would be rejected. The module therefore sends `no_ip_allowed = true` or `null`, and emits `acl_rules` blocks only when there are rules (`dynamic`), `ip = null` and `scaleway_ranges = true`/`null` per rule so the two selectors are never both present.
- Validations in `variables.tf` (each named in the spec with its message): exactly one mode; exactly one selector per rule; `can(cidrhost(ip, 0))` for the CIDR; at most one `scaleway_ranges` rule. Each gets a rejected-input test run.
- `check "api_server_acl_not_open_to_world"` in `main.tf` warns for `0.0.0.0/0` or `::/0` (the provider default rule that custom ACLs replace); a `check` and not a validation because it is legal, just pointless (`terraform-security`, guardrails).
- **No perpetual diff**: rule `id` and `srn` are computed and not configured; the block is a set, so rule order does not matter. A second plan must be empty; verified in the unit tests as far as a mock provider allows and in the manual apply of `examples/complete` (not run by the planning or by tests; needs an account and a user request).
- **State migration**: nothing to migrate; the resource is created only when the input is set. Removing the input destroys the resource and the provider restores the default allow-all rule.
- **Lock-out risk** (accepted, documented): the API server then refuses callers outside the rules, including the machine that runs `tofu apply` for resources that use the cluster's kubeconfig. The variable description and README say to include the CI/runner egress CIDR. `no_ip_allowed = true` isolates the cluster entirely and is documented as such.
- Alternative rejected: a separate sub-module or separate `acl_rules` boolean flags; one object keeps the contract small.

### D3. Outputs
`srn` (cluster, available in 2.86.0), `upgrade_available` (cluster, available in 2.86.0), and `private_network_id` and `srn` in each `node_pools` entry. New outputs and new map keys are minor on their own (`terraform-versioning`); none is sensitive, none carries a secret. Descriptions are required (`terraform-outputs` store spec is fetched at apply).

### D4. Provider floor
`versions.tf` goes from `~> 2.86` to `~> 2.89`. D1 needs 2.87.0, so need-driven policy requires a raise; 2.89 (not 2.87) matches the sibling modules and the version the diff and tests were checked against. The module classification is therefore **major** (`terraform-versioning`, `terraform-providers` raised-floor scenario). `required_version` stays `>= 1.10.0`: nothing adopted needs a newer core.

## Risks / Trade-offs

- [Raised floor forces `tofu init -upgrade` and a provider bump for consumers] → major bump, reason in commit body and README, no input removed.
- [ACL lock-out] → opt-in, default `null`, runner CIDR guidance, world-open warning is the only guardrail; full-isolation requires an explicit `true`.
- [Pool network replaced when changed] → provider `ForceNew`; README states it; the value is optional and defaults to no change.
- [Bare UUID in `private_network_id` would replace pools every plan] → rejected by validation.
- [Mock provider cannot prove an empty second plan] → covered by reasoning on Computed/Set semantics above and by a manual apply of `examples/complete` when the user asks for one.

## Migration Plan

1. Release as a new major tag. Consumers run `tofu init -upgrade`, then `tofu plan`: expected result is no changes for configurations that do not set the new inputs.
2. To opt in: set `node_pools.<name>.private_network_id` (new pool recommended) and/or `api_server_acl`.
3. Rollback: pin the previous tag; the ACL (if set) must be removed first, as the earlier module version does not manage it, otherwise it stays in state of the newer version only.

## Implementation notes

- The mock provider fills Optional+Computed arguments with random values at plan time, so the `null` default of the pool `private_network_id` is asserted on the input (`try(var.node_pools["default"].private_network_id, null)`), not on the planned argument, which is passed through unchanged.
- The ACL tests need a UUID-shaped cluster ID and a valid region; `tests/main.tftest.hcl` overrides `scaleway_k8s_cluster.this` (`id`, `region`) for that.
- The output test (`outputs_expose_identifiers`) uses `command = apply` against the mock provider only; nothing is created.
- `examples/complete` passes `private_network_id = var.workers_private_network_id` (default `null`) uncommented: a commented line left the variable unused and failed tflint `terraform_unused_declarations`; `null` keeps the pool on the cluster network.
