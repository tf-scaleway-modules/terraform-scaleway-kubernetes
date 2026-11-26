# Changelog

All notable changes to this project will be documented in this file.


## [4.0.0] - 2026-11-25
- Require OpenTofu or Terraform 1.11.0 and validate with both tools

BREAKING: required_version is raised from >= 1.10.0 to >= 1.11.0.
Upgrade note: consumers need OpenTofu or Terraform >= 1.11.0.

Pin opentofu 1.13.10 and terraform 1.17.2, add the validate:terraform
CI job to the release needs, run the pre-commit Terraform hooks with
tofu, and move the terraform standards store to v2.1.0.
- Rewrite input and output descriptions as single-line prose so they render on the Terraform Registry
## [3.0.0] - 2026-11-01
- Add cluster network CIDRs and pool security groups, replace the project lookup with project_id and trim kubeconfig outputs

BREAKING: v3.0.0.

- organization_id and project_name are removed: pass project_id if the
  project is not the provider default (compare with the project_id
  output first, a wrong value replaces the cluster).
- node_pools[*].region is removed: pools take the cluster region.
- node_pools[*].tags are merged with the module tags.
- Output kubeconfig is one object (or null): kubeconfig[0].x becomes
  kubeconfig.x. Outputs kubeconfig_host, kubeconfig_cluster_ca_certificate,
  kubeconfig_token and helm_provider_config are removed: use apiserver_url
  or kubernetes_provider_config.
- New network_cidrs (pod, service, service DNS IP), opt-in
  node_pools[*].security_group_id, root volume types sbs_5k and sbs_15k,
  and node IDs and private IPs in the node_pools output.

See "Upgrading from v2 to v3" in the README.
## [2.0.0] - 2026-10-31
- Require Scaleway provider ~> 2.89, add pool private networks and an API server ACL

Raise the provider floor from ~> 2.86 to ~> 2.89 because
scaleway_k8s_pool.private_network_id needs provider 2.87.0 (major bump).

- node_pools[*].private_network_id (region/uuid) attaches a pool to another
  Private Network of the cluster's VPC; null keeps the cluster network.
- api_server_acl creates scaleway_k8s_acl (CIDR rules, Scaleway ranges or
  full isolation) with a check that warns on 0.0.0.0/0 and ::/0.
- New outputs srn and upgrade_available; node_pools entries gain srn and
  private_network_id.

BREAKING: provider constraint is now ~> 2.89; run tofu init -upgrade.

Upgrade notes:
- Changing private_network_id on an existing pool replaces the pool.
- api_server_acl can lock out the machine that runs tofu apply; include the
  CI/runner egress CIDR.
- user_data is stored in state: do not put secrets in it.
## [1.2.2] - 2026-10-28
- Reject reserved cloud-init user_data key and warn on ignored pool versions

- Reject the cloud-init key in node_pools[*].user_data, which the provider reserves.
- Warn with a check when a pool sets version while upgrade_pools is not false, since the provider then ignores it.
- Remove the unreachable public_ip_disabled precondition and say "must" in the autoscaling error.
- Document helm_provider_config as identical to kubernetes_provider_config.
- Add the first unit tests (tests/main.tftest.hcl).
No upgrade action needed.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
## [1.2.1] - 2026-10-28
- Key the pre-commit cache on mise.toml and .pre-commit-config.yaml

The cache was keyed on the branch, so a branch kept tools installed by the previous mise, which the new one no longer puts on PATH (tofu not found). Keying it on the files that define the toolchain, as in scaleway-compute and scaleway-storage, starts a fresh cache whenever the toolchain changes and shares it across branches and tags.
- Install mise 2026.10.17 in CI to avoid the GitHub API rate limit

The pre-commit job installed an old mise that resolves every tool through api.github.com without a token, and failed with 403 rate-limit errors on the shared office runner whenever its cache was cold (new refs such as merge requests and tags). mise 2026.9.14 and later resolve releases through mise-versions.jdx.dev.
- Run validate:specs in merge request pipelines

A job without rules: only runs in branch and tag pipelines, so the merge request pipeline did not validate openspec/. rules: when: always matches the other validate jobs.
- Adopt OpenSpec and publish the baseline specs

Planning adopts OpenSpec, aligned with the other leminnov Terraform
modules: the engineering standards come from the quality, repository and
terraform OpenSpec stores. openspec/config.yaml follows the terraform-module profile
(stores pinned at quality v1.2.6, repository v4.1.0, terraform v1.2.6) and
AGENTS.md, imported by CLAUDE.md, routes to them. openspec/specs/ holds the
baseline specification of the module as released, produced by the archived
adopt-openspec change. The openspec-* skills are installed for Claude Code
and OpenCode, openspec 1.14.3 and node are pinned in mise.toml with the
spec-validate and spec-setup tasks, and the validate:specs CI job runs
openspec validate --all --strict. The module contract is unchanged.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
## [1.2.0] - 2026-10-14
- feat: support pool labels, taints, user data and independent pool upgrades

- node_pools: add labels, taints, startup_taints, user_data and version.
- Add upgrade_pools to upgrade pools separately from the cluster.
- autoscaler_config: add log_level and skip_nodes_with_local_storage.
- Bump the scaleway provider constraint to ~> 2.86; example kubernetes and
  helm providers to ~> 3.3 (helm v3 provider syntax).

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
- rollback
- fix organization id as data
## [1.1.0] - 2025-12-25
- Updates Scaleway provider version

Updates the required Scaleway provider version in README.md to a more flexible range (~> 2.64).

This allows for minor version updates while ensuring compatibility.
## [1.0.0] - 2025-12-14
- Simplifies and updates cluster configuration

Streamlines cluster configuration by removing unnecessary settings and updating defaults.

- Removes unused configurations for a cleaner setup.
- Corrects autoscaler expander option for proper autoscaling behavior.
- Sets a default batch node pool size to ensure resources are available.
- Makes kubeconfig host output sensitive to prevent accidental exposure.
- Enforces node pool size and min_size to be at least 1 to avoid configuration issues.
- Refactors module for enhanced Kubernetes deployment

Improves the Scaleway Kubernetes Terraform module with comprehensive configuration options and enhanced features for Kapsule cluster management.

The changes include:
- Introduces a new README with detailed documentation and usage examples.
- Restructures the example configurations for clarity.
- Enhances variable definitions with validations and descriptions.
- Simplifies resource configurations for better management.
- Adds output configurations for Terraform providers.
- Refactors module for improved Scaleway K8s management

Migrates the Terraform module to use more explicit and descriptive variables, data sources, and resource configurations for managing Scaleway Kubernetes clusters (Kapsule).

This change streamlines cluster creation, configuration, and node pool management, enhancing the module's usability and flexibility. It introduces comprehensive examples, clear output definitions, and validations.
- generalize container runtime map variable
- run pre commit
- create scw kapsule module
- Initial commit
