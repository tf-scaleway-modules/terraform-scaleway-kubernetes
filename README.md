# Scaleway Kubernetes Terraform Module

[![Apache 2.0][apache-shield]][apache]
[![Terraform][terraform-badge]][terraform-url]
[![Scaleway Provider][scaleway-badge]][scaleway-url]
[![Latest Release][release-badge]][release-url]

A production-ready Terraform module for creating and managing **Scaleway Kapsule** Kubernetes clusters with comprehensive configuration options. It works with OpenTofu >= 1.11.0 and Terraform >= 1.11.0.

## Features

- **Cluster Management**: Full Kapsule and Multicloud cluster support with dedicated control plane options
- **Node Pools**: Multiple node pools with independent scaling, zones, and configurations
- **Autoscaling**: Cluster autoscaler with fine-grained tuning parameters
- **Auto-Upgrade**: Automatic Kubernetes version upgrades with configurable maintenance windows
- **Networking**: VPC Private Network integration with optional public IP management
- **Security**: OIDC authentication support, admission plugins, and feature gates
- **Storage**: Configurable root volumes (type, size) for nodes
- **Lifecycle**: Upgrade policies, kubelet arguments, and placement groups
- **Node Metadata**: Kubernetes labels, taints and startup taints reconciled on pool nodes, plus pool user data
- **API Server Access Control**: Optional allow-list (`api_server_acl`) of CIDRs or Scaleway ranges, or full isolation
- **Pool Private Network**: Optional per-pool `private_network_id` to attach a pool to another Private Network of the cluster's VPC
- **Independent Pool Upgrades**: Set `upgrade_pools = false` and pin `node_pools[*].version` to upgrade pools separately from the cluster

## Upgrading from v3 to v4

Consumers need OpenTofu or Terraform >= 1.11.0: `required_version` was raised from `>= 1.10.0`. Nothing else changes (inputs, outputs, state and the `~> 2.89` provider floor are unchanged). Rollback: pin the previous v3 tag.

## Upgrading from v2 to v3

Run `tofu init -upgrade && tofu plan` after the edits below: expect only in-place tag updates on pools that set `tags`. The provider floor (`~> 2.89`) and `required_version` are unchanged. Rollback: pin `v2.0.0`; no state format change.

| Change | Edit |
|--------|------|
| Input `organization_id` removed | Delete it |
| Input `project_name` removed, `project_id` added | Pass `project_id = "<uuid>"` if the project is not the provider default. A wrong value replaces the cluster (ForceNew): compare with the v2 `project_id` output first |
| `node_pools[*].region` removed | Delete it; the pool region is the cluster region |
| `node_pools[*].tags` merged with the module `tags` | Expect one in-place tag update per pool that sets `tags` |
| Output `kubeconfig` is one object (or `null`) instead of a list | Replace `kubeconfig[0].x` with `kubeconfig.x` |
| Outputs `kubeconfig_host`, `kubeconfig_cluster_ca_certificate`, `kubeconfig_token` removed | Use `apiserver_url` or `kubernetes_provider_config.host`, `.cluster_ca_certificate` (already decoded), `.token` |
| Output `helm_provider_config` removed | Use `kubernetes_provider_config` |

New optional inputs (no change when unset): `network_cidrs` (pod, service, DNS IP; setting or changing a value replaces the cluster and a custom value cannot be unset), `node_pools[*].security_group_id`, and root volume types `sbs_5k` and `sbs_15k`.

Cautions:

- **Pool `security_group_id`**: a custom group must keep node registration and Kubernetes traffic open or the nodes never become ready. Leave it unset to keep the Scaleway-managed group.
- **Pool `private_network_id`**: use the `region/uuid` form. Changing it on an existing pool replaces the pool; prefer a new pool name and drain the old one.
- **`api_server_acl`**: the API server refuses callers outside the rules, including the machine that runs `tofu apply`; include the CI/runner egress CIDR. Setting it back to `null` restores allow-all.
- **Kubeconfig in state**: the kubeconfig token is a computed cluster attribute and stays in the state, marked sensitive; provider 2.89 has no write-only or ephemeral kubeconfig. Protect the state accordingly.
- **`user_data`** is stored in state: never put secrets in it.

## Usage

### Input reference

#### `autoscaler_config`

Set to `null` (default) to disable the cluster autoscaler. `log_level` is a number from 0 (least verbose) to 4.

#### `node_pools`

Map keyed by the pool name. At least one pool is required.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `node_type` | `string` | required | Node commercial type |
| `size` | `number` | required | Number of nodes |
| `min_size` | `number` | `null` | Autoscaling lower bound |
| `max_size` | `number` | `null` | Autoscaling upper bound |
| `autoscaling` | `bool` | `false` | Enable pool autoscaling |
| `autohealing` | `bool` | `true` | Enable node autohealing |
| `container_runtime` | `string` | `"containerd"` | `containerd` or `crio` |
| `kubelet_args` | `map(string)` | `{}` | Kubelet arguments |
| `user_data` | `map(string)` | `{}` | Map of key to content; the `cloud-init` key is reserved |
| `labels` | `map(string)` | `{}` | Kubernetes node labels |
| `taints` | `list(object)` | `[]` | `key`, `value`, `effect`; reconciled on existing nodes |
| `startup_taints` | `list(object)` | `[]` | Same shape as `taints`; applied at node creation only |
| `placement_group_id` | `string` | `null` | Placement group |
| `zone` | `string` | `null` | Pool zone |
| `root_volume_type` | `string` | `null` | `l_ssd`, `b_ssd`, `sbs_5k` or `sbs_15k` |
| `root_volume_size_in_gb` | `number` | `null` | Root volume size, at least 20 |
| `public_ip_disabled` | `bool` | `false` | Disable public IPs on nodes |
| `private_network_id` | `string` | `null` | `region/uuid`; `null` uses the cluster's Private Network. Changing it replaces the pool |
| `security_group_id` | `string` | `null` | `null` keeps the Scaleway-managed group; a custom group must allow node registration and Kubernetes traffic or nodes never become ready |
| `tags` | `list(string)` | `[]` | Merged with the module tags |
| `wait_for_pool_ready` | `bool` | `true` | Wait for the pool to be ready |
| `version` | `string` | `null` | Only honored when `upgrade_pools = false` |
| `upgrade_policy` | `object` | `null` | `max_unavailable` (default `1`) and `max_surge` (default `0`) |

#### `api_server_acl`

Set either `no_ip_allowed = true` (full isolation) or `rules`, each with a `description` and exactly one of `ip` (a CIDR) or `scaleway_ranges = true`. `null` creates no ACL and keeps the provider default (allow all). The API server then refuses every caller outside the rules, including the machine that runs `tofu apply`: include the CI/runner egress CIDR. Setting it back to `null` restores allow-all.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.0 |
| <a name="requirement_scaleway"></a> [scaleway](#requirement\_scaleway) | ~> 2.89 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_scaleway"></a> [scaleway](#provider\_scaleway) | ~> 2.89 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [scaleway_k8s_acl.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/k8s_acl) | resource |
| [scaleway_k8s_cluster.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/k8s_cluster) | resource |
| [scaleway_k8s_pool.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/k8s_pool) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admission_plugins"></a> [admission\_plugins](#input\_admission\_plugins) | List of Kubernetes admission plugins to enable on the cluster | `list(string)` | `[]` | no |
| <a name="input_api_server_acl"></a> [api\_server\_acl](#input\_api\_server\_acl) | API server allow-list: set either `no_ip_allowed = true` (full isolation) or `rules`. `null` creates no ACL and keeps the provider default (allow all). The API server refuses callers outside the rules, including the machine that runs apply; see Input reference in the README. | <pre>object({<br/>    no_ip_allowed = optional(bool, false)<br/>    rules = optional(list(object({<br/>      ip              = optional(string)<br/>      scaleway_ranges = optional(bool, false)<br/>      description     = optional(string)<br/>    })), [])<br/>  })</pre> | `null` | no |
| <a name="input_apiserver_cert_sans"></a> [apiserver\_cert\_sans](#input\_apiserver\_cert\_sans) | Additional Subject Alternative Names for the API server certificate | `list(string)` | `[]` | no |
| <a name="input_auto_upgrade"></a> [auto\_upgrade](#input\_auto\_upgrade) | Auto upgrade configuration for the cluster. When enabled, kubernetes\_version must be a minor version (e.g., '1.31'). | <pre>object({<br/>    enabled                       = optional(bool, false)<br/>    maintenance_window_start_hour = optional(number, 3)<br/>    maintenance_window_day        = optional(string, "sunday")<br/>  })</pre> | `{}` | no |
| <a name="input_autoscaler_config"></a> [autoscaler\_config](#input\_autoscaler\_config) | Cluster autoscaler configuration. Set to null to disable the autoscaler. | <pre>object({<br/>    disable_scale_down               = optional(bool, false)<br/>    scale_down_delay_after_add       = optional(string, "10m")<br/>    scale_down_unneeded_time         = optional(string, "10m")<br/>    estimator                        = optional(string, "binpacking")<br/>    expander                         = optional(string, "random")<br/>    ignore_daemonsets_utilization    = optional(bool, false)<br/>    balance_similar_node_groups      = optional(bool, false)<br/>    expendable_pods_priority_cutoff  = optional(number, -10)<br/>    scale_down_utilization_threshold = optional(number, 0.5)<br/>    max_graceful_termination_sec     = optional(number, 600)<br/>    skip_nodes_with_local_storage    = optional(bool)<br/>    log_level                        = optional(number)<br/>  })</pre> | `null` | no |
| <a name="input_cni"></a> [cni](#input\_cni) | Container Network Interface plugin | `string` | `"cilium"` | no |
| <a name="input_delete_additional_resources"></a> [delete\_additional\_resources](#input\_delete\_additional\_resources) | Delete additional resources (block volumes, loadbalancers) on cluster deletion | `bool` | `false` | no |
| <a name="input_description"></a> [description](#input\_description) | Description for the Kubernetes cluster | `string` | `null` | no |
| <a name="input_feature_gates"></a> [feature\_gates](#input\_feature\_gates) | List of Kubernetes feature gates to enable on the cluster | `list(string)` | `[]` | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | Kubernetes version for the cluster (e.g., '1.31' for auto-upgrade or '1.31.0' for fixed version) | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name of the Kubernetes cluster | `string` | n/a | yes |
| <a name="input_network_cidrs"></a> [network\_cidrs](#input\_network\_cidrs) | Cluster network ranges: pod and service CIDRs and the cluster DNS IP. An unset member keeps the Scaleway default. Setting or changing a value replaces the cluster, and a custom value cannot be unset. | <pre>object({<br/>    pod            = optional(string)<br/>    service        = optional(string)<br/>    service_dns_ip = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_node_pools"></a> [node\_pools](#input\_node\_pools) | Map of node pools to create, keyed by the pool name. See Input reference in the README for every attribute. | <pre>map(object({<br/>    node_type = string<br/>    size      = number<br/><br/>    min_size    = optional(number)<br/>    max_size    = optional(number)<br/>    autoscaling = optional(bool, false)<br/>    autohealing = optional(bool, true)<br/><br/>    container_runtime = optional(string, "containerd")<br/>    kubelet_args      = optional(map(string), {})<br/>    user_data         = optional(map(string), {})<br/><br/>    labels = optional(map(string), {})<br/>    taints = optional(list(object({<br/>      key    = string<br/>      value  = string<br/>      effect = string<br/>    })), [])<br/>    startup_taints = optional(list(object({<br/>      key    = string<br/>      value  = string<br/>      effect = string<br/>    })), [])<br/><br/>    placement_group_id = optional(string)<br/>    zone               = optional(string)<br/><br/>    root_volume_type       = optional(string)<br/>    root_volume_size_in_gb = optional(number)<br/><br/>    public_ip_disabled = optional(bool, false)<br/>    private_network_id = optional(string)<br/>    security_group_id  = optional(string)<br/><br/>    tags = optional(list(string), [])<br/><br/>    wait_for_pool_ready = optional(bool, true)<br/>    version             = optional(string)<br/>    upgrade_policy = optional(object({<br/>      max_unavailable = optional(number, 1)<br/>      max_surge       = optional(number, 0)<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_oidc_config"></a> [oidc\_config](#input\_oidc\_config) | OpenID Connect configuration for the cluster API server | <pre>object({<br/>    issuer_url      = string<br/>    client_id       = string<br/>    username_claim  = optional(string)<br/>    username_prefix = optional(string)<br/>    groups_claim    = optional(list(string))<br/>    groups_prefix   = optional(string)<br/>    required_claim  = optional(list(string))<br/>  })</pre> | `null` | no |
| <a name="input_private_network_id"></a> [private\_network\_id](#input\_private\_network\_id) | ID of the Scaleway VPC Private Network (format: region/uuid) | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | ID of the Scaleway project that owns the cluster (UUID). Null uses the provider default project. Changing it replaces the cluster. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | Scaleway region for the cluster (defaults to provider region) | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to the Kubernetes cluster | `list(string)` | `[]` | no |
| <a name="input_type"></a> [type](#input\_type) | Type of Kubernetes cluster | `string` | `"kapsule"` | no |
| <a name="input_upgrade_pools"></a> [upgrade\_pools](#input\_upgrade\_pools) | Upgrade node pools together with the cluster (provider default: `true`). Set to `false` to upgrade each pool separately through the `version` attribute of each `node_pools` entry. | `bool` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_apiserver_url"></a> [apiserver\_url](#output\_apiserver\_url) | URL of the Kubernetes API server |
| <a name="output_cni"></a> [cni](#output\_cni) | CNI plugin used by the cluster |
| <a name="output_created_at"></a> [created\_at](#output\_created\_at) | Creation timestamp of the cluster |
| <a name="output_id"></a> [id](#output\_id) | ID of the Kubernetes cluster |
| <a name="output_kubeconfig"></a> [kubeconfig](#output\_kubeconfig) | Kubeconfig object of the cluster (config\_file, host, cluster\_ca\_certificate, token); null when unavailable |
| <a name="output_kubeconfig_file"></a> [kubeconfig\_file](#output\_kubeconfig\_file) | Raw kubeconfig file content (YAML format); null when unavailable |
| <a name="output_kubernetes_provider_config"></a> [kubernetes\_provider\_config](#output\_kubernetes\_provider\_config) | Configuration block for the Kubernetes Terraform provider |
| <a name="output_name"></a> [name](#output\_name) | Name of the Kubernetes cluster |
| <a name="output_node_pool_ids"></a> [node\_pool\_ids](#output\_node\_pool\_ids) | Map of node pool names to their IDs |
| <a name="output_node_pool_versions"></a> [node\_pool\_versions](#output\_node\_pool\_versions) | Map of node pool names to their Kubernetes versions |
| <a name="output_node_pools"></a> [node\_pools](#output\_node\_pools) | Map of node pool configurations and status |
| <a name="output_organization_id"></a> [organization\_id](#output\_organization\_id) | Scaleway organization ID |
| <a name="output_project_id"></a> [project\_id](#output\_project\_id) | Scaleway project ID |
| <a name="output_region"></a> [region](#output\_region) | Region where the cluster is deployed |
| <a name="output_srn"></a> [srn](#output\_srn) | Scaleway Resource Name (SRN) of the Kubernetes cluster |
| <a name="output_status"></a> [status](#output\_status) | Status of the Kubernetes cluster |
| <a name="output_tags"></a> [tags](#output\_tags) | Tags applied to the cluster |
| <a name="output_type"></a> [type](#output\_type) | Type of the Kubernetes cluster |
| <a name="output_updated_at"></a> [updated\_at](#output\_updated\_at) | Last update timestamp of the cluster |
| <a name="output_upgrade_available"></a> [upgrade\_available](#output\_upgrade\_available) | Whether a Kubernetes version upgrade is available for the cluster |
| <a name="output_version"></a> [version](#output\_version) | Kubernetes version of the cluster |
| <a name="output_wildcard_dns"></a> [wildcard\_dns](#output\_wildcard\_dns) | Wildcard DNS record pointing to all cluster nodes |
<!-- END_TF_DOCS -->

## Contributing

Changes are planned with [OpenSpec](https://github.com/Fission-AI/OpenSpec): `openspec/specs/` is the module's current contract and [AGENTS.md](AGENTS.md) routes to the engineering standards. Behaviour changes, new inputs, outputs or resources go through a change proposal (`/openspec-propose`) before any code.

1. Open an issue describing the change.
2. Create a branch from `develop`, run `mise install` and `pre-commit install` once, and `mise run spec-setup` once per machine to register the standards stores.
3. For a behaviour change, run `/openspec-propose`, implement with `/openspec-apply-change`, then `/openspec-archive-change` merges the deltas into `openspec/specs/`.
4. Run `pre-commit run -a` and `mise run spec-validate`; add unit tests in `tests/main.tftest.hcl` (run with `tofu test`) for new behaviour.
5. Write commit subjects that read as `CHANGELOG.md` lines: the changelog is generated by git-cliff (`mise run changelog`), not edited by hand.
6. Open a merge request against `develop`.

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for full details.

Copyright 2025 - This module is independently maintained and not affiliated with Scaleway.

## Disclaimer

This module is provided "as is" without warranty of any kind, express or implied. The authors and contributors are not responsible for any issues, damages, or losses arising from the use of this module. No official support is provided. Use at your own risk.

[apache]: https://opensource.org/licenses/Apache-2.0
[apache-shield]: https://img.shields.io/badge/License-Apache%202.0-blue.svg

[terraform-badge]: https://img.shields.io/badge/Terraform-%3E%3D1.11-623CE4
[terraform-url]: https://www.terraform.io

[scaleway-badge]: https://img.shields.io/badge/Scaleway%20Provider-~%3E2.89-4f0599
[scaleway-url]: https://registry.terraform.io/providers/scaleway/scaleway/

[release-badge]: https://img.shields.io/gitlab/v/release/leminnov/terraform/modules/scaleway-kubernetes?include_prereleases&sort=semver
[release-url]: https://gitlab.com/leminnov/terraform/modules/scaleway-kubernetes/-/releases
