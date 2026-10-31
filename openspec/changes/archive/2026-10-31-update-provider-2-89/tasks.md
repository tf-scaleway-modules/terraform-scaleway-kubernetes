## 1. Provider floor and pool Private Network

- [x] 1.1 `versions.tf`: set the `scaleway/scaleway` constraint to `~> 2.89`. Verify: `tofu init -backend=false` resolves 2.89.x and `tofu validate` passes.
- [x] 1.2 `variables.tf`: add `private_network_id = optional(string)` to the `node_pools` object (group "Network") and a validation `v.private_network_id == null || can(regex("^[a-z]{2}-[a-z]{3}/[0-9a-f]{8}-...-[0-9a-f]{12}$", v.private_network_id))` with the message "Node pool private_network_id must be in format 'region/uuid' (e.g., 'fr-par/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx')." Verify: `tofu validate`.
- [x] 1.3 `main.tf`: pass `private_network_id = each.value.private_network_id` in `scaleway_k8s_pool.this`. Verify: `tofu validate`.
- [x] 1.4 `tests/main.tftest.hcl` (`mock_provider "scaleway"`, `command = plan`): a run asserting a pool with `private_network_id` is planned with it; a run asserting a pool without it plans `null` for the argument; a run `pool_private_network_requires_region` with a bare UUID and `expect_failures = [var.node_pools]`. Verify: `tofu test`.

## 2. API server ACL

- [x] 2.1 `variables.tf`: add `api_server_acl` (shape in design D2, default `null`, description with the lock-out warning and the runner CIDR advice) in a new "API Server Access Control" group, with the four validations and messages from the cluster delta spec. Verify: `tofu validate`.
- [x] 2.2 `main.tf`: add `scaleway_k8s_acl.this` with `count`, `cluster_id`, `region`, `no_ip_allowed = ... ? true : null`, `dynamic "acl_rules"` (`ip`, `scaleway_ranges = ... ? true : null`, `description`), and `check "api_server_acl_not_open_to_world"` with the spec message. Verify: `tofu validate`.
- [x] 2.3 `tests/main.tftest.hcl`: runs for no ACL (resource count 0), CIDR allow-list (one rule), full isolation, plus one `expect_failures = [var.api_server_acl]` run per validation (neither mode, both modes, rule with both selectors, rule with no selector, invalid CIDR, two `scaleway_ranges` rules) and one run with `0.0.0.0/0` using `expect_failures = [check.api_server_acl_not_open_to_world]`. Verify: `tofu test`.

## 3. Outputs

- [x] 3.1 `outputs.tf`: add outputs `srn` and `upgrade_available` (with descriptions) and the keys `srn` and `private_network_id` to each `node_pools` entry. Verify: `tofu validate`; a test run asserts the outputs exist with the mock provider.

## 4. Examples and docs

- [x] 4.1 `examples/complete`: add an `api_server_acl` using a new `api_server_acl_cidrs` variable (list(string), default `[]`, passes `null` when empty) and a commented `workers` pool line `private_network_id = var.workers_private_network_id` backed by a variable with default `null`; `examples/minimal` unchanged. Verify: `tofu init -backend=false && tofu validate` in `examples/complete`.
- [x] 4.2 README: provider badge and compatibility to 2.89; upgrade notes (major bump reason: floor `~> 2.89` because `scaleway_k8s_pool.private_network_id` needs 2.87.0; run `tofu init -upgrade`; a changed pool `private_network_id` replaces the pool; ACL lock-out; `user_data` is stored in state, no secrets). The terraform-docs block is regenerated, not hand-edited.

## 5. Verify and commit

- [x] 5.1 Run `tofu fmt -recursive`, `tofu init -backend=false && tofu validate`, `tflint --recursive`, `tofu test`; report outputs as-is.
- [x] 5.2 Move any local `.terraform.lock.hcl` aside before `pre-commit run -a` and before pushing: with the lock file present terraform-docs writes the locked provider version (for example `2.89.0`) into the README instead of the constraint `~> 2.89`. Then run `pre-commit run -a` and restore nothing into the commit.
- [x] 5.3 Commit subject (reads as the CHANGELOG line, do not edit CHANGELOG.md): `Require Scaleway provider ~> 2.89, add pool private networks and an API server ACL` (no conventional prefix, per the repo's recent subjects). Body: reason for the major bump (floor raised for `scaleway_k8s_pool.private_network_id`, 2.87.0), `BREAKING: provider constraint is now ~> 2.89; run tofu init -upgrade`, and the other upgrade notes from 4.2.
- [x] 5.4 No `tofu apply` and no call to the Scaleway API unless the user asks; say so in the final report. `mise run spec-validate` passes.
