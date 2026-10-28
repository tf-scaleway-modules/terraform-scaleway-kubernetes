## MODIFIED Requirements

### Requirement: Provider configuration helpers
The module SHALL expose `kubernetes_provider_config` and `helm_provider_config`, both sensitive objects with `host`, `cluster_ca_certificate` (base64-decoded) and `token`, each `null` when the kubeconfig is unavailable. The description of `helm_provider_config` SHALL state that it is identical to `kubernetes_provider_config`.

#### Scenario: Configure the Kubernetes provider
- **WHEN** a caller passes `module.k8s.kubernetes_provider_config.host`, `.cluster_ca_certificate` and `.token` to the `kubernetes` provider
- **THEN** the provider authenticates against the cluster API server

#### Scenario: Identical helpers
- **WHEN** both helper outputs are read
- **THEN** they contain the same three values
