# Tasks

## 1. Core floor and toolchain

- [x] 1.1 `versions.tf`, `examples/complete/versions.tf`, `examples/minimal/versions.tf`: `required_version = ">= 1.11.0"`; drop the `// Open tofu 1.10.7` comment; confirm the examples' scaleway constraint equals the root's
- [x] 1.2 `mise.toml`: `opentofu = '1.13.10'`, add `terraform = '1.17.2'`; run `mise install`
- [x] 1.3 `openspec/config.yaml`: `terraform` store `ref: v2.1.0` (others unchanged); context `required_version >= 1.11.0`; run `mise run spec-setup` if the store is not at v2.1.0

## 2. CI and hooks

- [x] 2.1 `.gitlab/release.yml`: `validate:opentofu` image `1.13.10`; add `validate:terraform` (`hashicorp/terraform:1.17.2`, root plus `examples/*/`) after it; add it to `create:release` `needs:` after `validate:opentofu`
- [x] 2.2 `.pre-commit-config.yaml`: add `args: [--hook-config=--tf-path=tofu]` to `terraform_fmt`, `terraform_docs`, `terraform_tflint`
- [x] 2.3 `.github/workflows/ci.yml` and `release.yml`: `tofu_version: "1.13.10"`; add no job

## 3. Docs

- [x] 3.1 `AGENTS.md`: name OpenTofu >= 1.11.0 and Terraform >= 1.11.0; add `terraform init -backend=false && terraform validate` to the format/validate command
- [x] 3.2 `README.md` (outside the terraform-docs markers): compatibility sentence naming both tools, floor badge `%3E%3D1.11`, "Upgrading from v3 to v4" note ("consumers need OpenTofu or Terraform >= 1.11.0")
- [x] 3.3 Grep for stale `1.10.0`, `1.10.7`, `1.11.6`, `v1.2.6` and fix prose that refers to the old floor or pins (leave `CHANGELOG.md` and the archive)

## 4. Verification

- [x] 4.1 `mise exec -- tofu fmt -recursive -check`
- [x] 4.2 `tofu init -backend=false -upgrade && tofu validate` in the root and each `examples/*`
- [x] 4.3 `tflint --init && tflint --recursive`
- [x] 4.4 `tofu test`
- [x] 4.5 Terraform compatibility in a scratch copy (rsync excluding `.terraform`, lock file, `.git`, `mise*.toml`; `T=$(mise which terraform)`; init and validate root and examples)
- [x] 4.6 `mise exec -- openspec validate --all --strict`
- [x] 4.7 `pre-commit run -a` with every `.terraform.lock.hcl` moved outside the repo, restored afterwards

## 5. Commit

- [x] 5.1 One signed commit (`git commit -S`), imperative subject reading as a CHANGELOG line without a `feat:` prefix; body starts with `BREAKING:` and the upgrade note "consumers need OpenTofu or Terraform >= 1.11.0". Do not edit `CHANGELOG.md`, do not tag.
