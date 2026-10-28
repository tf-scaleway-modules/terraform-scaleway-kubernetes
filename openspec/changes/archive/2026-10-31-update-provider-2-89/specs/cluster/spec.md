## ADDED Requirements

### Requirement: API server access control
The module SHALL create one `scaleway_k8s_acl` for the cluster only when `var.api_server_acl` is not `null`, and SHALL create none otherwise. `api_server_acl` has either `no_ip_allowed = true` (full isolation, default `false`) or a non-empty `rules` list (default `[]`), never both and never neither. Each rule has a `description` and exactly one of `ip` (a CIDR) or `scaleway_ranges = true`. At most one rule SHALL set `scaleway_ranges = true`.

#### Scenario: ACL not configured
- **WHEN** `api_server_acl = null`
- **THEN** no `scaleway_k8s_acl` is planned and the cluster keeps the provider-side default rule

#### Scenario: CIDR allow-list
- **WHEN** `api_server_acl = { rules = [{ ip = "203.0.113.0/24", description = "office" }] }`
- **THEN** one `scaleway_k8s_acl` is planned for the cluster with that single rule

#### Scenario: Full isolation
- **WHEN** `api_server_acl = { no_ip_allowed = true }`
- **THEN** one `scaleway_k8s_acl` is planned with `no_ip_allowed = true` and no rule

#### Scenario: Neither mode chosen
- **WHEN** `api_server_acl = {}`
- **THEN** planning fails with "api_server_acl must set either no_ip_allowed = true or at least one rule, not both and not neither."

#### Scenario: Both modes chosen
- **WHEN** `api_server_acl = { no_ip_allowed = true, rules = [{ ip = "203.0.113.0/24" }] }`
- **THEN** planning fails with the same message

#### Scenario: Rule with both selectors
- **WHEN** a rule sets `ip = "203.0.113.0/24"` and `scaleway_ranges = true`
- **THEN** planning fails with "Each api_server_acl rule must set exactly one of ip or scaleway_ranges = true."

#### Scenario: Rule with no selector
- **WHEN** a rule sets neither `ip` nor `scaleway_ranges`
- **THEN** planning fails with the same message

#### Scenario: Invalid CIDR
- **WHEN** a rule sets `ip = "203.0.113.5"`
- **THEN** planning fails with "api_server_acl rule ip must be a CIDR (e.g. '203.0.113.0/24')."

#### Scenario: Two Scaleway-ranges rules
- **WHEN** two rules set `scaleway_ranges = true`
- **THEN** planning fails with "api_server_acl may contain at most one rule with scaleway_ranges = true."

### Requirement: World-open ACL warning
A `check` SHALL warn, without failing, when an `api_server_acl` rule allows `0.0.0.0/0` or `::/0`, because it restricts nothing.

#### Scenario: World-open rule
- **WHEN** `api_server_acl = { rules = [{ ip = "0.0.0.0/0" }] }`
- **THEN** the check warns "api_server_acl contains a world-open rule (0.0.0.0/0 or ::/0); it does not restrict API server access."

#### Scenario: Restricted rule
- **WHEN** every rule is a narrower CIDR or `scaleway_ranges = true`
- **THEN** no warning is raised
