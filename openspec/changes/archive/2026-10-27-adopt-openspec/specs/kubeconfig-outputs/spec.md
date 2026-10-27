## ADDED Requirements

### Requirement: Sensitive kubeconfig outputs
The outputs `kubeconfig`, `kubeconfig_file`, `kubeconfig_cluster_ca_certificate` and `kubeconfig_token` SHALL be marked `sensitive = true`.

#### Scenario: Credentials hidden from plan output
- **WHEN** the root module outputs `module.k8s.kubeconfig_token`
- **THEN** Terraform requires the caller's output to be marked sensitive and does not print the value

### Requirement: Kubeconfig-derived values
`kubeconfig_file`, `kubeconfig_host`, `kubeconfig_cluster_ca_certificate` and `kubeconfig_token` SHALL be read from the first element of the cluster `kubeconfig` list and SHALL be `null` when that element is unavailable. `kubeconfig` SHALL expose the full kubeconfig list of the cluster.

#### Scenario: Kubeconfig available
- **WHEN** the cluster is applied
- **THEN** `kubeconfig_host` is the host and `kubeconfig_file` the raw YAML of the first kubeconfig

#### Scenario: Kubeconfig not available
- **WHEN** the cluster has no kubeconfig element
- **THEN** `kubeconfig_file`, `kubeconfig_host`, `kubeconfig_cluster_ca_certificate` and `kubeconfig_token` are `null`

### Requirement: Provider configuration helpers
The module SHALL expose `kubernetes_provider_config` and `helm_provider_config`, both sensitive objects with `host`, `cluster_ca_certificate` (base64-decoded) and `token`, each `null` when the kubeconfig is unavailable.

#### Scenario: Configure the Kubernetes provider
- **WHEN** a caller passes `module.k8s.kubernetes_provider_config.host`, `.cluster_ca_certificate` and `.token` to the `kubernetes` provider
- **THEN** the provider authenticates against the cluster API server

#### Scenario: Identical helpers
- **WHEN** both helper outputs are read
- **THEN** they contain the same three values
