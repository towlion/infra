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
        "ec2:DescribeImages",
        "ec2:DescribeInstanceAttribute",
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceTypes",
        "ec2:DescribeKeyPairs",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVolumes",
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
        "route53:ListResourceRecordSets"
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
./towlion-infra init --provider <aws|digitalocean> [--region <region>] [--domain <domain>]
```

Sets the cloud provider, generates an SSH key pair (stored in `keys/towlion`), and runs `tofu init`.

#### `plan` -- Preview changes

```sh
./towlion-infra plan [--region <region>] [--domain <domain>]
```

Runs `tofu plan` to show what resources will be created, modified, or destroyed.

#### `apply` -- Provision infrastructure

```sh
./towlion-infra apply [-y|--auto-approve] [--region <region>] [--domain <domain>]
```

Creates the server, data volume, firewall, and SSH key. Prints connection details on completion.

#### `destroy` -- Tear down infrastructure

```sh
./towlion-infra destroy [-y|--auto-approve] [--region <region>] [--domain <domain>]
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

Shows the server IP, SSH command, bootstrap command, GitHub Actions secrets (`SERVER_HOST`, `SERVER_SSH_KEY`), and DNS nameservers (when a domain is configured).

### Options

| Flag | Description |
|---|---|
| `--provider <aws\|digitalocean>` | Cloud provider (required for `init`) |
| `--region <region>` | Override default region |
| `--domain <domain>` | Root domain for DNS zone and records (e.g. `example.com`) |
| `-y`, `--auto-approve` | Skip interactive approval (`apply`, `destroy`) |

## Typical workflow

```sh
# 1. Initialize with your provider
./towlion-infra init --provider digitalocean

# 2. Preview what will be created (optionally with DNS)
./towlion-infra plan --domain example.com

# 3. Provision the server (with DNS)
./towlion-infra apply --domain example.com

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
outputs.tf              # Server IP, SSH command, bootstrap command, nameservers
providers.tf            # Provider configuration
modules/
  aws/                  # AWS resources (EC2, EBS, SG, key pair)
  digitalocean/         # DO resources (Droplet, volume, firewall, SSH key)
keys/                   # Generated SSH keys (git-ignored)
```
