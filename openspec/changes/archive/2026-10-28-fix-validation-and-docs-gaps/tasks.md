## 1. Code
- [x] 1.1 Remove the dead `public_ip_disabled` precondition in `main.tf`
- [x] 1.2 Autoscaling precondition message: "must be specified"
- [x] 1.3 Add the `cloud-init` user_data key validation in `variables.tf`
- [x] 1.4 Add the pool version `check` block in `main.tf`
- [x] 1.5 Mark `helm_provider_config` as identical to `kubernetes_provider_config` in its description

## 2. Tests and examples
- [x] 2.1 Create `tests/main.tftest.hcl` (mock provider): happy path, autoscaling precondition, `cloud-init` rejection, version check warning
- [x] 2.2 `examples/complete` reviewed: no input changes, nothing to update

## 3. Verify
- [x] 3.1 `tofu fmt -recursive`, `tofu validate`, `tflint --recursive`, `tofu test`, `pre-commit run -a`
