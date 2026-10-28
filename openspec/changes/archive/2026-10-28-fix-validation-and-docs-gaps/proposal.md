## Why

Writing the `adopt-openspec` baseline surfaced six gaps between what the module says and what it enforces. This change fixes them without altering any resource the module produced before.

## What Changes

| # | Issue | Decision | Breaking |
|---|-------|----------|----------|
| 1 | `public_ip_disabled` precondition (`private_network_id != null`) can never fail: `private_network_id` is required and its regex validation already rejects null | Code fix: remove the dead precondition and the requirement describing it | No |
| 2 | CHANGELOG 1.0.0 says the kubeconfig host output is sensitive, `kubeconfig_host` is not | Left: a host is not a secret, the baseline requirement already lists only the four secret-bearing outputs; CHANGELOG is generated and not edited | No |
| 3 | `kubernetes_provider_config` and `helm_provider_config` are identical | Doc fix: `helm_provider_config` description says it is identical and that the Helm provider can use `kubernetes_provider_config`; no output removed | No |
| 4 | `user_data` comment says the `cloud-init` key is reserved, nothing enforces it | Code fix: validation rejecting the `cloud-init` key. The provider documents the key as reserved (`cloud_init` attribute, not exposed by this module), so a pool using it did not work | No (patch) |
| 5 | Autoscaling precondition says "should be specified" though it fails; `min_size`/`max_size` fall back to `size` through `coalesce` | Message fix ("must"). `coalesce` kept: non-autoscaling pools rely on it and removing it changes planned resources; the precondition already reads the raw inputs, so autoscaling still requires both explicitly | No |
| 6 | `node_pools[*].version` has no validation; `upgrade_pools` not checked against it | New `check` block warning when a pool sets `version` while `upgrade_pools` is not `false` (the provider ignores it then). No format validation: the provider documents no format and one could reject working configs | No |

Semver: **patch**. Nothing is removed or renamed, no default changes, no resource changes; the new validation only rejects input that could not work, the new check only warns (`terraform-versioning`, `terraform-security` for the check).

State: nothing new lands in state; no secret-bearing input is added.

## Capabilities

### Modified Capabilities
- `node-pools`: autoscaling message, `cloud-init` user_data key rejected, dead public IP precondition removed, version-without-`upgrade_pools = false` warning
- `kubeconfig-outputs`: `helm_provider_config` documented as duplicate

## Impact

`main.tf` (precondition removed, message, check), `variables.tf` (validation), `outputs.tf` (description), `tests/main.tftest.hcl` (new), `examples/complete` unchanged (no input added or changed), README (terraform-docs).
