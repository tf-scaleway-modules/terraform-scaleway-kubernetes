# AGENTS.md — terraform-modules-scaleway-kubernetes

## Project
OpenTofu/Terraform module: a Scaleway Kapsule/Multicloud Kubernetes cluster with its node pools. Published on GitLab at leminnov/terraform/modules/scaleway-kubernetes;
consumers pin a git tag. Planning uses OpenSpec (`openspec/`). Engineering
standards live in the `quality`, `repository` and `terraform` OpenSpec stores, the single
source of truth; this file only routes to them.

## Non-negotiables (apply to EVERY change, no fetch needed)
Every request targets simple, efficient, secure, production-level code:
- Simple: the smallest change that solves the task; no speculative abstraction,
  unused option, dead code or placeholder left behind.
- Efficient: no redundant call, loop, resource or step the tooling already performs.
- Secure: no secret in source, logs or state; least privilege; inputs validated;
  safe defaults; no control weakened silently.
- Production-level: errors handled, idempotent, tested, documented, verified with the
  repository tasks before reporting, and reported as-is.
The checkable form of each line is the `quality` store (`quality-simplicity`,
`quality-efficiency`, `quality-security`, `quality-production-readiness`).
- No `provider {}` or `backend {}` blocks in the module; no `local-exec`, no CLI calls.
- `description` on every variable and output; `type` on every variable; no `any`.
- Secrets: `sensitive = true` (+ `ephemeral = true`), no default, sent through
  write-only `*_wo` arguments with a `*_wo_version` companion where the provider has them.
- `for_each` over `count`; resource label `this` for singletons; snake_case everywhere.
- Send values in the form the server reads back: a second plan after apply must be empty.
- Every behaviour change ships with a unit test in `tests/main.tftest.hcl`, an update
  to `examples/complete/`, and a commit subject that reads as its `CHANGELOG.md` line
  (git-cliff generates the file).
- Never edit the README between `BEGIN_TF_DOCS` / `END_TF_DOCS`; terraform-docs owns it.

## Standards lookup
Engineering standards are OpenSpec specs in the stores listed under `references:`
in `openspec/config.yaml` (`quality`, `repository`, `terraform`). Inside the
OpenSpec skills the index of every spec, with a one-line summary, is already in
the instructions: fetch the specs whose id matches what you touch, follow them
and cite them in your summary. Outside the skills:

    openspec list --specs --store <store>
    openspec show <spec-id> --type spec --store <store>

Easy to miss: for a repository file read the `repository-<topic>` base spec, then
its `terraform-repo-<topic>` extension; `terraform-versioning` for every
major/minor/patch call; `terraform-security` for anything secret-bearing or a
`check` block.

If a store is not registered on this machine, stop and say so; `mise run
spec-setup` registers them. Do not guess the standard.

## Workflow
- Behaviour changes, new inputs/outputs, new resources: OpenSpec workflow
  (`/openspec-propose`, then `/openspec-apply-change`, then `/openspec-archive-change`). Do not code directly.
- The `openspec-*` skills are installed for Claude Code (`.claude/skills/`) and OpenCode
  (`.opencode/skills/`, which reads this file natively); after bumping `openspec` in
  `mise.toml`, run `openspec update` so both sets stay identical.
- Small fixes (typos, description wording, obvious bugs, tool bumps): code directly,
  still applying the non-negotiables and the relevant standard.

## Precedence and deviations
1. An approved OpenSpec change (proposal/design) for this task
2. This file's non-negotiables
3. `quality`, `repository` and `terraform` store standards
4. Existing patterns in this repository

Never deviate silently: add a `# DEVIATION(<spec-id>): <reason>` comment and list it
in your summary.

## Commands
- Format / validate: `tofu fmt -recursive`, `tofu init -backend=false && tofu validate`, `tflint --recursive`
- Tests: `tofu test` (unit tests in `tests/main.tftest.hcl`, mock provider, no server)
- Everything incl. README regeneration: `pre-commit run -a`; changelog: `mise run changelog`
- Specs: `mise run spec-validate`; standards stores: `mise run spec-setup`
