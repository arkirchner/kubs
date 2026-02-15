# Agent Requirements

These requirements apply to all work in this repository.

- Use OpenTofu for all infrastructure definitions; keep configuration under `tofu/`.
- Manage tool versions with direnv + nix flake; keep `flake.nix` up to date.
- Keep state out of git; use `.tfvars` files for environment-specific inputs.
- Do not add secrets or credentials to the repo.
- Update `README.md` when workflows or prerequisites change.
- Favor minimal, composable modules; keep the local test setup a single-node VM.
