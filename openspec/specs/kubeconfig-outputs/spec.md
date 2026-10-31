# kubeconfig-outputs Specification

## Purpose
Define the kubeconfig-derived outputs and provider configuration helpers, and which of them are sensitive.

## Requirements

### Requirement: Sensitive kubeconfig outputs
The outputs `kubeconfig`, `kubeconfig_file` and `kubernetes_provider_config` SHALL be marked `sensitive = true`.

#### Scenario: Credentials hidden from plan output
- **WHEN** the root module outputs `module.k8s.kubeconfig_file`
- **THEN** Terraform requires the caller's output to be marked sensitive and does not print the value

### Requirement: Kubeconfig-derived values
`kubeconfig` SHALL be the first element of the cluster kubeconfig list as one object (`config_file`, `host`, `cluster_ca_certificate`, `token`) and `kubeconfig_file` its raw YAML; both SHALL be `null` when no element exists.

#### Scenario: Kubeconfig available
- **WHEN** the cluster is applied
- **THEN** `kubeconfig.host` is the API server host and `kubeconfig_file` the raw YAML

#### Scenario: Kubeconfig not available
- **WHEN** the cluster has no kubeconfig element
- **THEN** `kubeconfig` and `kubeconfig_file` are `null`

### Requirement: Provider configuration helpers
The module SHALL expose `kubernetes_provider_config`, a sensitive object with `host`, `cluster_ca_certificate` (base64-decoded) and `token`, each `null` when the kubeconfig is unavailable. The Helm provider uses the same values.

#### Scenario: Configure the Kubernetes provider
- **WHEN** a caller passes `module.k8s.kubernetes_provider_config.host`, `.cluster_ca_certificate` and `.token` to the `kubernetes` provider
- **THEN** the provider authenticates against the cluster API server

#### Scenario: Identical helpers
- **WHEN** the Helm provider is configured from `kubernetes_provider_config`
- **THEN** it receives the same `host`, `cluster_ca_certificate` and `token` as the Kubernetes provider

#### Scenario: Removed helm helper
- **WHEN** a caller reads `helm_provider_config`
- **THEN** planning fails because the output does not exist
