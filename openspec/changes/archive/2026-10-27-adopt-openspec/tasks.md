## 1. Scaffold

- [x] 1.1 Remove nothing (first adoption); add `openspec/config.yaml`, `AGENTS.md`, `CLAUDE.md`
- [x] 1.2 Install `openspec-*` skills in `.claude/skills/` and `.opencode/skills/`
- [x] 1.3 Add `scripts/openspec-setup.sh`, mise tasks `spec-validate` / `spec-setup`, CI job `validate:specs`

## 2. Baseline specs

- [x] 2.1 Fill `context`, rules and operations of `openspec/config.yaml` and the placeholders of `AGENTS.md` for this module
- [x] 2.2 Write delta specs for `module-contract`, `cluster`, `node-pools`, `kubeconfig-outputs` from the current code
- [x] 2.3 Add the OpenSpec paragraph and steps to the README Contributing section

## 3. Verification

- [x] 3.1 `openspec validate --all --strict` passes (same command as the `validate:specs` CI job)
- [x] 3.2 `pre-commit run` passes on the changed files
- [x] 3.3 Archive the change so the capabilities become main specs under `openspec/specs/`
