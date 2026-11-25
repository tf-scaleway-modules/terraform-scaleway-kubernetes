## MODIFIED Requirements

### Requirement: Tool and provider version constraints
The module SHALL declare one `required_version = ">= 1.11.0"`, read by both OpenTofu and Terraform, and the provider `scaleway/scaleway` with version `~> 2.89` in `versions.tf`.

#### Scenario: Supported toolchain
- **WHEN** the module is initialised with OpenTofu or Terraform 1.11.0 or newer and a scaleway provider 2.89.x or newer 2.x
- **THEN** initialisation succeeds

#### Scenario: Old toolchain
- **WHEN** the module is initialised with OpenTofu or Terraform older than 1.11.0
- **THEN** initialisation fails on the `required_version` constraint

#### Scenario: Old provider
- **WHEN** the module is initialised with a scaleway provider older than 2.89.0
- **THEN** initialisation fails on the provider constraint

#### Scenario: Validated with both tools
- **WHEN** `validate` runs in the module root and in each `examples/*` with OpenTofu and with Terraform
- **THEN** both succeed
