# Scaleway Kubernetes Terraform Module

[![Apache 2.0][apache-shield]][apache]
[![Terraform][terraform-badge]][terraform-url]
[![Scaleway Provider][scaleway-badge]][scaleway-url]
[![Latest Release][release-badge]][release-url]

A Terraform module for creating and managing **Scaleway Kapsule** Kubernetes clusters. This module provisions a fully configured Kubernetes cluster with customizable node pools, autoscaling, auto-upgrade, and integration with Scaleway VPC Private Networks.

## Features

- Scaleway Kapsule (managed Kubernetes) cluster provisioning
- Multiple node pools with flexible configuration
- Cluster autoscaler support with configurable parameters
- Auto-upgrade with maintenance window scheduling
- VPC Private Network integration
- Support for feature gates and admission plugins
- Configurable container runtime (containerd)

## Usage Examples

Comprehensive examples are available in the [`examples/`](examples/) directory:

- **[Minimal](examples/minimal/)** - Simplest configuration for quick start
- **[Complete](examples/complete/)** - Full-featured production setup

### Basic Usage

```hcl
module "kubernetes" {
  source = "path/to/scaleway-kubernetes"

  organization_id    = "your-organization-id"
  project_name       = "my-project"
  private_network_id = "fr-par/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

  cluster_name    = "my-cluster"
  cluster_version = "1.31"
  cluster_cni     = "cilium"

  node_pools = {
    default = {
      node_type           = "DEV1-M"
      size                = 2
      min_size            = 1
      max_size            = 5
      autoscaling         = true
      autohealing         = true
      wait_for_pool_ready = true
      container_runtime   = "containerd"
      tags                = ["env:production"]
    }
  }
}
```

<!-- BEGIN_TF_DOCS -->

<!-- END_TF_DOCS -->

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for full details.

Copyright 2025 - This module is independently maintained and not affiliated with Scaleway.

## Disclaimer

This module is provided "as is" without warranty of any kind, express or implied. The authors and contributors are not responsible for any issues, damages, or losses arising from the use of this module. No official support is provided. Use at your own risk.

[apache]: https://opensource.org/licenses/Apache-2.0
[apache-shield]: https://img.shields.io/badge/License-Apache%202.0-blue.svg

[terraform-badge]: https://img.shields.io/badge/Terraform-%3E%3D0.13-623CE4
[terraform-url]: https://www.terraform.io

[scaleway-badge]: https://img.shields.io/badge/Scaleway%20Provider-2.64-4f0599
[scaleway-url]: https://registry.terraform.io/providers/scaleway/scaleway/

[release-badge]: https://img.shields.io/gitlab/v/release/leminnov/terraform/modules/scaleway-kubernetes?include_prereleases&sort=semver
[release-url]: https://gitlab.com/leminnov/terraform/modules/scaleway-kubernetes/-/releases
