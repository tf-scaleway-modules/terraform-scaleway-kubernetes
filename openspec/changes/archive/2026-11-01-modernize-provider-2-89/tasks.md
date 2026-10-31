## 1. Project and region

- [x] 1.1 Delete `data.tf`; replace `organization_id` and `project_name` by `project_id` (string, default `null`, UUID validation "Project ID must be a valid UUID."); pass it to the cluster. Verify: `tofu validate` passes and `grep -r scaleway_account_project .` finds nothing outside `openspec/`
- [x] 1.2 Output `project_id` reads the cluster attribute; remove the `override_data` block from `tests/main.tftest.hcl`. Verify: `tofu test`

## 2. Cluster network CIDRs

- [x] 2.1 Add `network_cidrs` (object, optional `pod`, `service`, `service_dns_ip`, default `{}`) with the two validations of the cluster spec; pass to `pod_cidr`, `service_cidr`, `service_dns_ip`. Verify: tests for the default, a custom value, and a rejected-input run per validation (`expect_failures = [var.network_cidrs]`)

## 3. Node pools

- [x] 3.1 Remove the pool `region` attribute; set the pool region to the cluster region. Verify: test asserting the planned region equals the cluster region
- [x] 3.2 Merge tags: `distinct(concat(var.tags, each.value.tags))`. Verify: test with overlapping tags asserts each tag once
- [x] 3.3 Add `security_group_id` (optional string, `null`); document in the variable that the group must allow node traffic. Verify: test with and without the value
- [x] 3.4 Extend `root_volume_type` validation and message to `l_ssd, b_ssd, sbs_5k, sbs_15k`. Verify: accepted `sbs_15k` run and rejected `nvme` run
- [x] 3.5 Send `kubelet_args` as `null` when empty (like `labels`/`user_data`). Verify: test asserts unset
- [x] 3.6 Extend the `node_pools` output with `security_group_id` and node `id`, `private_ips`. Verify: apply-mode mock test reads the new keys

## 4. Outputs

- [x] 4.1 `kubeconfig` becomes `try(...kubeconfig[0], null)`; `kubeconfig_file` derives from it; remove `kubeconfig_host`, `kubeconfig_cluster_ca_certificate`, `kubeconfig_token`, `helm_provider_config`. Verify: tests (apply mode, mock) cover the object and the sensitive flag; removed outputs are absent from `outputs.tf`

## 5. Examples and docs

- [x] 5.1 `examples/minimal` and `examples/complete`: drop `organization_id`/`project_name` (variables and module call), add `project_id` (default `null`), `network_cidrs` (commented or `{}`), a pool `security_group_id` (variable default `null`), use `kubernetes_provider_config` in the provider block. Verify: `tofu validate` in both examples (move any local `.terraform.lock.hcl` aside, delete produced `.terraform/` afterwards) and `tflint --recursive` has no unused declarations
- [x] 5.2 README: replace the "Upgrade notes" with "Upgrading from v2 to v3" listing every row of the proposal's breaking-changes table with its edit, the `project_id` replacement warning, the kubeconfig-in-state note and the lock-out/security-group cautions. Verify: section present; text between `BEGIN_TF_DOCS` and `END_TF_DOCS` untouched

## 6. Quality gates

- [x] 6.1 Run `mise exec -- tofu fmt -recursive`, `tofu init -backend=false && tofu validate`, `tflint --recursive`, `tofu test`; report output as-is
- [x] 6.2 Move a local `.terraform.lock.hcl` aside, run `mise exec -- pre-commit run -a` (terraform-docs regenerates the README tables), restore. Verify: clean exit and the README table shows `~> 2.89`
- [x] 6.3 `mise exec -- openspec validate --all --strict` passes
- [x] 6.4 Commit subject (becomes the CHANGELOG line): `Add cluster network CIDRs and pool security groups, replace the project lookup with project_id and trim kubeconfig outputs`, body `BREAKING:` listing removed `organization_id`, `project_name`, pool `region`, outputs `kubeconfig_host`, `kubeconfig_cluster_ca_certificate`, `kubeconfig_token`, `helm_provider_config`, the `kubeconfig` type change and the pool tag merge. Verify: `.cliff.toml` (`conventional_commits = false`) prints the subject as-is via `mise run changelog`

## 7. Real-account checks (only on request; never part of the unit run)

- [ ] 7.1 Apply the v2.0.0 `examples/complete`, switch to this change with `project_id` set to the `project_id` output, run `tofu plan`: expect only pool tag updates, then an empty second plan
- [ ] 7.2 Create one pool with `root_volume_type = "sbs_15k"` and one with a custom `security_group_id`; confirm acceptance and an empty second plan; if `sbs_*` is rejected, drop it from the validation and the spec
- [ ] 7.3 Create a cluster with `network_cidrs.pod` set; confirm an empty second plan and that changing the value plans a replacement
