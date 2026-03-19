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
| DNS (optional) | DO Domain + records | Route 53 zone + records |

A cloud-init script (`cloud-init.sh`) automatically detects, formats, and mounts the data volume at `/data`.

When a `--domain` is provided, a DNS zone is created with root (`@`) and wildcard (`*`) A records pointing to the server IP. This covers `APP_DOMAIN`, `OPS_DOMAIN`, and `PREVIEW_DOMAIN` subdomains. After provisioning, point your domain's nameservers at your registrar to the values shown in `./towlion-infra output`.

### DNS configuration

After `apply` completes, you need to point your domain to the provisioned nameservers at your domain registrar.

**DigitalOcean** uses fixed nameservers:

- `ns1.digitalocean.com`
- `ns2.digitalocean.com`
- `ns3.digitalocean.com`

For a root domain, set these as custom nameservers at your registrar. For a subdomain, add NS records for the subdomain prefix in the parent zone pointing to each of these.

**AWS Route 53** assigns unique nameservers per hosted zone. These are only known after `apply` runs — there is no fixed set.

**To configure your domain:**

1. Run `./towlion-infra output` and copy the nameservers listed.

2. **Root domain** (e.g. `example.com`):
   1. Log in to your domain registrar (e.g. Namecheap, Cloudflare, GoDaddy).
   2. Find the domain's DNS or nameserver settings and switch to **custom nameservers**.
   3. Enter the nameservers from step 1.

3. **Subdomain** (e.g. `wit.example.com`):
   1. Log in to the DNS provider that manages the parent zone (`example.com`).
   2. Add NS records for the subdomain prefix (e.g. `wit`) pointing to each nameserver from step 1.
   3. This delegates only the subdomain to Route 53 / DigitalOcean, leaving the parent zone unchanged.

DNS propagation typically takes a few minutes but can take up to 48 hours.

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

## AWS IAM policy

When using AWS, create a dedicated IAM user with only the permissions needed to provision infrastructure. Attach the following policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EC2Provisioning",
      "Effect": "Allow",
      "Action": [
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:AttachVolume",
        "ec2:CreateKeyPair",
        "ec2:CreateSecurityGroup",
        "ec2:CreateTags",
        "ec2:CreateVolume",
        "ec2:DeleteKeyPair",
        "ec2:DeleteSecurityGroup",
        "ec2:DeleteVolume",
        "ec2:Describe*",
        "ec2:DetachVolume",
        "ec2:ImportKeyPair",
        "ec2:RevokeSecurityGroupEgress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:RunInstances",
        "ec2:TerminateInstances"
      ],
      "Resource": "*"
    },
    {
      "Sid": "Route53DNS",
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets",
        "route53:CreateHostedZone",
        "route53:DeleteHostedZone",
        "route53:GetChange",
        "route53:GetHostedZone",
        "route53:ListHostedZones",
        "route53:ListResourceRecordSets",
        "route53:ListTagsForResource"
      ],
      "Resource": "*"
    }
  ]
}
```

The `Route53DNS` statement is only required when using the `--domain` flag. You can omit it if you don't need DNS management.

To set up credentials:

1. **Sign in** to the [AWS Management Console](https://console.aws.amazon.com/) and open the **IAM** console.
2. **Create a custom policy** — go to **Policies > Create policy**, switch to the **JSON** tab, paste the policy above, click **Next**, and name it `TowlionInfraProvisioning`.
3. **Create an IAM user** — go to **Users > Create user** and enter a username (e.g. `towlion-infra`).
4. **Attach the policy** — on the permissions step, choose **Attach policies directly**, search for `TowlionInfraProvisioning`, and select it.
5. **Create access keys** — open the new user, go to **Security credentials > Create access key**, select **Command Line Interface (CLI)**, and copy the access key ID and secret.
6. **Add credentials to `.env.local`**:
   ```
   AWS_ACCESS_KEY_ID=<your-access-key-id>
   AWS_SECRET_ACCESS_KEY=<your-secret-access-key>
   ```

## Usage

```
./towlion-infra <command> [options]
```

### Commands

#### `init` -- Initialize infrastructure

```sh
./towlion-infra init --provider <aws|digitalocean>
```

Sets the cloud provider, generates an SSH key pair (stored in `keys/towlion`), and runs `tofu init`.

#### `plan` -- Preview changes

```sh
./towlion-infra plan [--region <region>] [--domain <domain>]
```

Runs `tofu plan` to show what resources will be created, modified, or destroyed. Saves the plan to `.tfplan` so that a subsequent `apply` can execute it without repeating flags.

#### `apply` -- Provision infrastructure

```sh
./towlion-infra apply [-y|--auto-approve] [--region <region>] [--domain <domain>]
```

Creates the server, data volume, firewall, and SSH key. Prints connection details on completion.

If a saved plan exists (from a prior `plan` command), `apply` uses it directly — no flags needed. Otherwise, flags are required as usual.

#### `destroy` -- Tear down infrastructure

```sh
./towlion-infra destroy [-y|--auto-approve] [--region <region>] [--domain <domain>]
```

Destroys all provisioned resources.

#### `status` -- Show current state

```sh
./towlion-infra status
```

Lists provisioned resources, or indicates if no infrastructure is provisioned.

#### `output` -- Display connection details

```sh
./towlion-infra output
```

Shows the server IP, SSH command, bootstrap command, GitHub Actions secrets (`SERVER_HOST`, `SERVER_SSH_KEY`), and DNS nameservers (when a domain is configured).

### Options

| Flag | Description |
|---|---|
| `--provider <aws\|digitalocean>` | Cloud provider (required for `init`) |
| `--region <region>` | Override default region (`plan`, `apply`, `destroy`) |
| `--domain <domain>` | Root domain for DNS zone and records (`plan`, `apply`, `destroy`) |
| `-y`, `--auto-approve` | Skip interactive approval (`apply`, `destroy`) |

## Examples

### Provision a DigitalOcean server with DNS

```sh
# Initialize the provider and generate SSH key
$ ./towlion-infra init --provider digitalocean
Provider set to digitalocean.
Generated SSH key: keys/towlion
Initializing the backend...
OpenTofu has been successfully initialized!

# Preview what will be created (saves plan to .tfplan)
$ ./towlion-infra plan --domain example.com
# ...
Plan: 7 to add, 0 to change, 0 to destroy.

Plan saved. Run './towlion-infra apply' to execute.

# Apply the saved plan (no flags needed)
$ ./towlion-infra apply
# ... tofu creates resources ...
Apply complete! Resources: 7 added, 0 changed, 0 destroyed.

=== Infrastructure provisioned ===

  Server IP:    203.0.113.42
  SSH Key:      keys/towlion

  Connect:      ssh -i keys/towlion root@203.0.113.42

  Bootstrap:    scp -i keys/towlion bootstrap-server.sh root@203.0.113.42:/tmp/ && ssh -i keys/towlion root@203.0.113.42 'bash /tmp/bootstrap-server.sh'

  GitHub Secrets:
    SERVER_HOST = 203.0.113.42
    SERVER_SSH_KEY = <contents of keys/towlion>

  DNS Nameservers (set these at your domain registrar):
    ns1.digitalocean.com
    ns2.digitalocean.com
    ns3.digitalocean.com

# Check what was provisioned
$ ./towlion-infra status
module.digitalocean.digitalocean_ssh_key.towlion
module.digitalocean.digitalocean_volume.data
module.digitalocean.digitalocean_droplet.server
module.digitalocean.digitalocean_volume_attachment.data
module.digitalocean.digitalocean_domain.zone[0]
module.digitalocean.digitalocean_record.root[0]
module.digitalocean.digitalocean_record.wildcard[0]
module.digitalocean.digitalocean_firewall.server

# Tear down when done
$ ./towlion-infra destroy
# ... tofu destroys resources ...
Infrastructure destroyed.
```

### Provision an AWS server (no DNS)

```sh
$ ./towlion-infra init --provider aws
Provider set to aws.
Generated SSH key: keys/towlion
OpenTofu has been successfully initialized!

$ ./towlion-infra apply -y
# ... tofu creates resources ...
Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

=== Infrastructure provisioned ===

  Server IP:    203.0.113.99
  SSH Key:      keys/towlion

  Connect:      ssh -i keys/towlion admin@203.0.113.99

  Bootstrap:    scp -i keys/towlion bootstrap-server.sh admin@203.0.113.99:/tmp/ && ssh -i keys/towlion admin@203.0.113.99 'bash /tmp/bootstrap-server.sh'

  GitHub Secrets:
    SERVER_HOST = 203.0.113.99
    SERVER_SSH_KEY = <contents of keys/towlion>
```

### Check infrastructure state

```sh
# When resources exist
$ ./towlion-infra status
module.aws.aws_key_pair.towlion
module.aws.aws_security_group.server
module.aws.aws_instance.server
module.aws.aws_ebs_volume.data
module.aws.aws_volume_attachment.data

# When nothing is provisioned
$ ./towlion-infra status
No infrastructure provisioned for aws.
```

## Project structure

```
.env.local              # Cloud credentials (git-ignored)
.tfplan                 # Saved tofu plan file (git-ignored)
towlion-infra           # CLI entrypoint
cloud-init.sh           # User-data script for data volume setup
bootstrap-server.sh     # Post-provision bootstrap script
main.tf                 # Root module — selects provider module
variables.tf            # Input variables
outputs.tf              # Server IP, SSH command, bootstrap command, nameservers
providers.tf            # Provider configuration
modules/
  aws/                  # AWS resources (EC2, EBS, SG, key pair)
  digitalocean/         # DO resources (Droplet, volume, firewall, SSH key)
keys/                   # Generated SSH keys (git-ignored)
```
