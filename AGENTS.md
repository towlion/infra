# AGENTS.md

## Project overview

towlion-infra is a Bash CLI (`towlion-infra`) that wraps OpenTofu to provision a single server on DigitalOcean or AWS. The infrastructure is defined in Terraform/OpenTofu HCL.

## Architecture

- `towlion-infra` — Bash entrypoint. Handles env loading, SSH key generation, and delegates to `tofu` commands.
- `main.tf` — Root module that conditionally enables either `modules/aws` or `modules/digitalocean` based on the `provider` variable.
- `modules/digitalocean/` — Droplet, block volume, firewall, SSH key.
- `modules/aws/` — EC2 instance, EBS volume, security group, key pair.
- `cloud-init.sh` — User-data script that detects and mounts the data volume at `/data`.

## Key conventions

- **Shell style**: Bash with `set -euo pipefail`. Use `die()` for fatal errors.
- **Provider parity**: Both provider modules should provision equivalent resources and expose the same outputs (`server_ip`, `ssh_command`, `bootstrap_command`).
- **Credentials**: Stored in `.env.local` (git-ignored). The CLI sources this file via `load_env()`. Use standard provider env vars (`DIGITALOCEAN_TOKEN`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`).
- **SSH keys**: Auto-generated Ed25519 keys stored in `keys/towlion` (git-ignored).
- **OpenTofu**: Use `tofu` (not `terraform`). Required version >= 1.6.0.

## File layout

```
.env.local              # Credentials (git-ignored)
.provider               # Current provider name (git-ignored)
towlion-infra           # CLI script
cloud-init.sh           # Cloud-init user-data
main.tf                 # Root module
variables.tf            # Input variables
outputs.tf              # Root outputs
providers.tf            # Provider blocks
modules/
  aws/main.tf           # AWS resources
  aws/outputs.tf
  aws/variables.tf
  digitalocean/main.tf  # DO resources
  digitalocean/outputs.tf
  digitalocean/variables.tf
keys/                   # SSH keys (git-ignored)
```

## Validation

- `bash -n towlion-infra` — Syntax-check the CLI script.
- `tofu validate` — Validate Terraform configuration (requires `tofu init` first).
- `shellcheck towlion-infra` — Lint the Bash script (if shellcheck is installed).

## Things to watch out for

- `.env.local` and `keys/` contain secrets — never commit them.
- Both provider modules must expose identical output names. If you add an output to one, add it to the other.
- The `cloud-init.sh` script runs as root on first boot. It must handle both AWS and DO device naming conventions.
- The CLI passes variables to tofu via `-var` flags, not tfvars files.
