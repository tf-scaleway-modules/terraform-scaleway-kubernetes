## Context

The module has no spec-driven history. The organisation's standards live in
OpenSpec stores; this change adopts the workflow and captures the released
behaviour as the baseline, without touching HCL.

## Goals / Non-Goals

**Goals:**
- Make `openspec/specs/` the reviewable description of the current contract.
- Route contributors and agents to the stores through `AGENTS.md`.
- Validate specs in CI with the same command used locally.

**Non-Goals:**
- Any change to `*.tf`, examples or behaviour.
- Fixing inconsistencies found while writing the specs (they are reported, not specified).

## Decisions

- **Stores pinned via the terraform-module profile**: `config.yaml` references
  `quality`, `repository` and `terraform` at released tags; `mise run spec-setup`
  registers them. Standards are not copied into this repository.
- **Skills for Claude Code and OpenCode**: both `.claude/skills/` and
  `.opencode/skills/` carry the same `openspec-*` skills; OpenCode reads `AGENTS.md` natively.
- **CI job `validate:specs`**: runs `openspec validate --all --strict`, the same
  command as `mise run spec-validate`, with the CLI version pinned by `OPENSPEC_VERSION`.
- **Capability split**: `module-contract` (versions, inputs, outputs overall),
  `cluster` (the `scaleway_k8s_cluster` resource and its optional blocks),
  `node-pools` (the `scaleway_k8s_pool` resource) and `kubeconfig-outputs`
  (sensitivity of credentials-bearing outputs). This follows the two resources
  and the sensitive-output concern, the unit a future change touches.
- **CHANGELOG via git-cliff kept**: `CHANGELOG.md` is generated from commit
  subjects (`mise run changelog`); specs and `AGENTS.md` ask for subjects that read as CHANGELOG lines.
- **Baseline describes code, not intent**: only behaviour visible in the HCL is specified.

## Risks / Trade-offs

- A spec could drift from the code; mitigated by requiring a change proposal for behaviour changes and by strict validation in CI.
- Without `tests/`, scenarios are not yet backed by `tofu test`; the first behaviour change adds `tests/main.tftest.hcl`.
