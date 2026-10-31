## MODIFIED Requirements

### Requirement: Cluster resource
The module SHALL create one `scaleway_k8s_cluster` named `var.name`, with `description`, `type`, `kubernetes_version` (as `version`), `cni`, `tags`, `region`, `project_id`, `private_network_id` and `delete_additional_resources` taken from the inputs.

#### Scenario: Minimal cluster
- **WHEN** `name`, `kubernetes_version`, `private_network_id` and one node pool are given
- **THEN** one cluster is planned, attached to the private network, with `delete_additional_resources = false`

## ADDED Requirements

### Requirement: Cluster network CIDRs
The module SHALL accept `network_cidrs` with optional `pod`, `service` and `service_dns_ip`, passed to `pod_cidr`, `service_cidr` and `service_dns_ip`; an unset member is sent as `null` (provider default). `pod` and `service` SHALL be CIDRs and `service_dns_ip` an IP address. Changing a set value replaces the cluster.

#### Scenario: Defaults
- **WHEN** `network_cidrs` is `{}`
- **THEN** none of the three arguments is set and the next plan shows no change

#### Scenario: Custom pod CIDR
- **WHEN** `network_cidrs = { pod = "10.244.0.0/16" }`
- **THEN** the cluster is planned with that `pod_cidr`

#### Scenario: Invalid pod CIDR
- **WHEN** `network_cidrs = { pod = "10.244.0.1" }`
- **THEN** planning fails with "network_cidrs.pod and network_cidrs.service must be CIDRs (e.g. '10.244.0.0/16')."

#### Scenario: Invalid DNS IP
- **WHEN** `network_cidrs = { service_dns_ip = "10.32.0.0/24" }`
- **THEN** planning fails with "network_cidrs.service_dns_ip must be an IP address (e.g. '10.32.0.10')."
