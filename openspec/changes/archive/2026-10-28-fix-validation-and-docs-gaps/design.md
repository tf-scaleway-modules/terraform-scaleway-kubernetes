## Context

All six items are validation, message or description gaps. No resource argument changes, so no perpetual diff and no state migration: a second plan stays empty and existing state is untouched.

## Decisions

- **Dead precondition removed** (`quality-simplicity`): `private_network_id` is a required string validated by regex, so `!= null` is always true.
- **`cloud-init` validation** on `node_pools` in `variables.tf`: `alltrue` over `keys(v.user_data)` not equal to `"cloud-init"`. The provider docs for `scaleway_k8s_pool.user_data` (provider ~> 2.86) say the key is reserved and `cloud_init` must be used; the module does not expose it, so the key is simply rejected.
- **Version warning** as a `check "pool_version_requires_upgrade_pools"` in `main.tf` (no `checks.tf` in this layout). Condition: no pool sets `version`, or `var.upgrade_pools == false`. A `check` warns instead of failing, so no working config is rejected. With `upgrade_pools = null` the provider default (true) applies, which ignores pool versions, hence the warning.
- **`coalesce` kept**: `min_size`/`max_size` default to `size` for fixed-size pools; changing it would alter planned resources.
- **Helm output kept**, description only; removal would be major.
- **Provider schema checked** with `tofu providers schema -json`: `user_data` is `map(string)`, `version` an optional computed string.
