# Scaleway Kubernetes Terraform Module

[![Apache 2.0][apache-shield]][apache]
[![Terraform][terraform-badge]][terraform-url]
[![Scaleway Provider][scaleway-badge]][scaleway-url]
[![Latest Release][release-badge]][release-url]

A production-ready Terraform module for creating and managing **Scaleway Kapsule** Kubernetes clusters with comprehensive configuration options.

## Features

- **Cluster Management**: Full Kapsule and Multicloud cluster support with dedicated control plane options
- **Node Pools**: Multiple node pools with independent scaling, zones, and configurations
- **Autoscaling**: Cluster autoscaler with fine-grained tuning parameters
- **Auto-Upgrade**: Automatic Kubernetes version upgrades with configurable maintenance windows
- **Networking**: VPC Private Network integration with optional public IP management
- **Security**: OIDC authentication support, admission plugins, and feature gates
- **Storage**: Configurable root volumes (type, size) for nodes
- **Lifecycle**: Upgrade policies, kubelet arguments, and placement groups

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10.0 |
| <a name="requirement_scaleway"></a> [scaleway](#requirement\_scaleway) | ~> 2.64 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_scaleway"></a> [scaleway](#provider\_scaleway) | ~> 2.64 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [scaleway_k8s_cluster.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/k8s_cluster) | resource |
| [scaleway_k8s_pool.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/k8s_pool) | resource |
| [scaleway_account_project.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/data-sources/account_project) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admission_plugins"></a> [admission\_plugins](#input\_admission\_plugins) | List of Kubernetes admission plugins to enable on the cluster | `list(string)` | `[]` | no |
| <a name="input_apiserver_cert_sans"></a> [apiserver\_cert\_sans](#input\_apiserver\_cert\_sans) | Additional Subject Alternative Names for the API server certificate | `list(string)` | `[]` | no |
| <a name="input_auto_upgrade"></a> [auto\_upgrade](#input\_auto\_upgrade) | Auto upgrade configuration for the cluster. When enabled, kubernetes\_version must be a minor version (e.g., '1.31'). | <pre>object({<br/>    enabled                       = optional(bool, false)<br/>    maintenance_window_start_hour = optional(number, 3)<br/>    maintenance_window_day        = optional(string, "sunday")<br/>  })</pre> | `{}` | no |
| <a name="input_autoscaler_config"></a> [autoscaler\_config](#input\_autoscaler\_config) | Cluster autoscaler configuration. Set to null to disable the autoscaler. | <pre>object({<br/>    disable_scale_down               = optional(bool, false)<br/>    scale_down_delay_after_add       = optional(string, "10m")<br/>    scale_down_unneeded_time         = optional(string, "10m")<br/>    estimator                        = optional(string, "binpacking")<br/>    expander                         = optional(string, "random")<br/>    ignore_daemonsets_utilization    = optional(bool, false)<br/>    balance_similar_node_groups      = optional(bool, false)<br/>    expendable_pods_priority_cutoff  = optional(number, -10)<br/>    scale_down_utilization_threshold = optional(number, 0.5)<br/>    max_graceful_termination_sec     = optional(number, 600)<br/>  })</pre> | `null` | no |
| <a name="input_cni"></a> [cni](#input\_cni) | Container Network Interface plugin | `string` | `"cilium"` | no |
| <a name="input_delete_additional_resources"></a> [delete\_additional\_resources](#input\_delete\_additional\_resources) | Delete additional resources (block volumes, loadbalancers) on cluster deletion | `bool` | `false` | no |
| <a name="input_description"></a> [description](#input\_description) | Description for the Kubernetes cluster | `string` | `null` | no |
| <a name="input_feature_gates"></a> [feature\_gates](#input\_feature\_gates) | List of Kubernetes feature gates to enable on the cluster | `list(string)` | `[]` | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | Kubernetes version for the cluster (e.g., '1.31' for auto-upgrade or '1.31.0' for fixed version) | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name of the Kubernetes cluster | `string` | n/a | yes |
| <a name="input_node_pools"></a> [node\_pools](#input\_node\_pools) | Map of node pool configurations. The map key is used as the pool name. | <pre>map(object({<br/>    # Required<br/>    node_type = string<br/>    size      = number<br/><br/>    # Scaling<br/>    min_size    = optional(number)<br/>    max_size    = optional(number)<br/>    autoscaling = optional(bool, false)<br/>    autohealing = optional(bool, true)<br/><br/>    # Runtime<br/>    container_runtime = optional(string, "containerd")<br/>    kubelet_args      = optional(map(string), {})<br/><br/>    # Placement<br/>    placement_group_id = optional(string)<br/>    zone               = optional(string)<br/>    region             = optional(string)<br/><br/>    # Storage<br/>    root_volume_type       = optional(string)<br/>    root_volume_size_in_gb = optional(number)<br/><br/>    # Network<br/>    public_ip_disabled = optional(bool, false)<br/><br/>    # Metadata<br/>    tags = optional(list(string), [])<br/><br/>    # Lifecycle<br/>    wait_for_pool_ready = optional(bool, true)<br/>    upgrade_policy = optional(object({<br/>      max_unavailable = optional(number, 1)<br/>      max_surge       = optional(number, 0)<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_oidc_config"></a> [oidc\_config](#input\_oidc\_config) | OpenID Connect configuration for the cluster API server | <pre>object({<br/>    issuer_url      = string<br/>    client_id       = string<br/>    username_claim  = optional(string)<br/>    username_prefix = optional(string)<br/>    groups_claim    = optional(list(string))<br/>    groups_prefix   = optional(string)<br/>    required_claim  = optional(list(string))<br/>  })</pre> | `null` | no |
| <a name="input_organization_id"></a> [organization\_id](#input\_organization\_id) | Scaleway organization ID | `string` | n/a | yes |
| <a name="input_private_network_id"></a> [private\_network\_id](#input\_private\_network\_id) | ID of the Scaleway VPC Private Network (format: region/uuid) | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name of the Scaleway project | `string` | `"default"` | no |
| <a name="input_region"></a> [region](#input\_region) | Scaleway region for the cluster (defaults to provider region) | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to the Kubernetes cluster | `list(string)` | `[]` | no |
| <a name="input_type"></a> [type](#input\_type) | Type of Kubernetes cluster | `string` | `"kapsule"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_apiserver_url"></a> [apiserver\_url](#output\_apiserver\_url) | URL of the Kubernetes API server |
| <a name="output_cni"></a> [cni](#output\_cni) | CNI plugin used by the cluster |
| <a name="output_created_at"></a> [created\_at](#output\_created\_at) | Creation timestamp of the cluster |
| <a name="output_helm_provider_config"></a> [helm\_provider\_config](#output\_helm\_provider\_config) | Configuration block for the Helm Terraform provider |
| <a name="output_id"></a> [id](#output\_id) | ID of the Kubernetes cluster |
| <a name="output_kubeconfig"></a> [kubeconfig](#output\_kubeconfig) | Complete kubeconfig configuration object for the cluster |
| <a name="output_kubeconfig_cluster_ca_certificate"></a> [kubeconfig\_cluster\_ca\_certificate](#output\_kubeconfig\_cluster\_ca\_certificate) | Base64 encoded cluster CA certificate |
| <a name="output_kubeconfig_file"></a> [kubeconfig\_file](#output\_kubeconfig\_file) | Raw kubeconfig file content (YAML format) |
| <a name="output_kubeconfig_host"></a> [kubeconfig\_host](#output\_kubeconfig\_host) | Kubernetes API server host from kubeconfig |
| <a name="output_kubeconfig_token"></a> [kubeconfig\_token](#output\_kubeconfig\_token) | Authentication token for the cluster |
| <a name="output_kubernetes_provider_config"></a> [kubernetes\_provider\_config](#output\_kubernetes\_provider\_config) | Configuration block for the Kubernetes Terraform provider |
| <a name="output_name"></a> [name](#output\_name) | Name of the Kubernetes cluster |
| <a name="output_node_pool_ids"></a> [node\_pool\_ids](#output\_node\_pool\_ids) | Map of node pool names to their IDs |
| <a name="output_node_pool_versions"></a> [node\_pool\_versions](#output\_node\_pool\_versions) | Map of node pool names to their Kubernetes versions |
| <a name="output_node_pools"></a> [node\_pools](#output\_node\_pools) | Map of node pool configurations and status |
| <a name="output_organization_id"></a> [organization\_id](#output\_organization\_id) | Scaleway organization ID |
| <a name="output_project_id"></a> [project\_id](#output\_project\_id) | Scaleway project ID |
| <a name="output_region"></a> [region](#output\_region) | Region where the cluster is deployed |
| <a name="output_status"></a> [status](#output\_status) | Status of the Kubernetes cluster |
| <a name="output_tags"></a> [tags](#output\_tags) | Tags applied to the cluster |
| <a name="output_type"></a> [type](#output\_type) | Type of the Kubernetes cluster |
| <a name="output_updated_at"></a> [updated\_at](#output\_updated\_at) | Last update timestamp of the cluster |
| <a name="output_version"></a> [version](#output\_version) | Kubernetes version of the cluster |
| <a name="output_wildcard_dns"></a> [wildcard\_dns](#output\_wildcard\_dns) | Wildcard DNS record pointing to all cluster nodes |
<!-- END_TF_DOCS -->

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for full details.

Copyright 2025 - This module is independently maintained and not affiliated with Scaleway.

## Disclaimer

This module is provided "as is" without warranty of any kind, express or implied. The authors and contributors are not responsible for any issues, damages, or losses arising from the use of this module. No official support is provided. Use at your own risk.

[apache]: https://opensource.org/licenses/Apache-2.0
[apache-shield]: https://img.shields.io/badge/License-Apache%202.0-blue.svg

[terraform-badge]: https://img.shields.io/badge/Terraform-%3E%3D1.10-623CE4
[terraform-url]: https://www.terraform.io

[scaleway-badge]: https://img.shields.io/badge/Scaleway%20Provider-~%3E2.64-4f0599
[scaleway-url]: https://registry.terraform.io/providers/scaleway/scaleway/

[release-badge]: https://img.shields.io/gitlab/v/release/leminnov/terraform/modules/scaleway-kubernetes?include_prereleases&sort=semver
[release-url]: https://gitlab.com/leminnov/terraform/modules/scaleway-kubernetes/-/releases
