# towlion-infra

CLI tool for provisioning Towlion server infrastructure on **DigitalOcean** or **AWS** using [OpenTofu](https://opentofu.org).

## What it provisions

Each provider creates an equivalent stack:

| Resource | DigitalOcean | AWS |
|---|---|---|
| Server | Droplet `s-2vcpu-4gb` | EC2 `t3.medium` (20 GB gp3 root) |
| OS | Debian 12 | Debian 12 |
| Data volume | 50 GB block volume | 50 GB gp3 EBS |
| Firewall | DO Firewall (22, 80, 443 inbound) | Security Group (22, 80, 443 inbound) |
| SSH key | DO SSH Key | EC2 Key Pair |
| Default region | `nyc3` | `us-east-1` |

A cloud-init script (`cloud-init.sh`) automatically detects, formats, and mounts the data volume at `/data`.

## Prerequisites

- [OpenTofu](https://opentofu.org) >= 1.6.0
- A DigitalOcean API token or AWS access keys

## Setup

Create a `.env.local` file with your cloud credentials:

```sh
# For DigitalOcean
DIGITALOCEAN_TOKEN=dop_v1_your_token_here

# For AWS
AWS_ACCESS_KEY_ID=your_key_id
AWS_SECRET_ACCESS_KEY=your_secret_key
```

## Usage

```
./towlion-infra <command> [options]
```

### Commands

#### `init` -- Initialize infrastructure

```sh
./towlion-infra init --provider <aws|digitalocean> [--region <region>]
```

Sets the cloud provider, generates an SSH key pair (stored in `keys/towlion`), and runs `tofu init`.

#### `plan` -- Preview changes

```sh
./towlion-infra plan [--region <region>]
```

Runs `tofu plan` to show what resources will be created, modified, or destroyed.

#### `apply` -- Provision infrastructure

```sh
./towlion-infra apply [-y|--auto-approve] [--region <region>]
```

Creates the server, data volume, firewall, and SSH key. Prints connection details on completion.

#### `destroy` -- Tear down infrastructure

```sh
./towlion-infra destroy [-y|--auto-approve] [--region <region>]
```

Destroys all provisioned resources.

#### `status` -- Show current state

```sh
./towlion-infra status
```

Displays the current Terraform state, or indicates if no infrastructure is provisioned.

#### `output` -- Display connection details

```sh
./towlion-infra output
```

Shows the server IP, SSH command, bootstrap command, and GitHub Actions secrets (`SERVER_HOST`, `SERVER_SSH_KEY`).

### Options

| Flag | Description |
|---|---|
| `--provider <aws\|digitalocean>` | Cloud provider (required for `init`) |
| `--region <region>` | Override default region |
| `-y`, `--auto-approve` | Skip interactive approval (`apply`, `destroy`) |

## Typical workflow

```sh
# 1. Initialize with your provider
./towlion-infra init --provider digitalocean

# 2. Preview what will be created
./towlion-infra plan

# 3. Provision the server
./towlion-infra apply

# 4. Connect to the server
ssh -i keys/towlion root@<server-ip>

# 5. Tear down when done
./towlion-infra destroy
```

## Project structure

```
.env.local              # Cloud credentials (git-ignored)
towlion-infra           # CLI entrypoint
cloud-init.sh           # User-data script for data volume setup
main.tf                 # Root module — selects provider module
variables.tf            # Input variables
outputs.tf              # Server IP, SSH command, bootstrap command
providers.tf            # Provider configuration
modules/
  aws/                  # AWS resources (EC2, EBS, SG, key pair)
  digitalocean/         # DO resources (Droplet, volume, firewall, SSH key)
keys/                   # Generated SSH keys (git-ignored)
```
