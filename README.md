# Bitwarden on AWS

Deploy Bitwarden (vaultwarden) on AWS spot instances with Amazon Linux 2023, Docker, Cloudflare Tunnel, and R2 storage.

Goal: under $2/month, zero public IPv4 costs, auto-healing spot instances.

## Architecture

![Architecture diagram](docs/cloudflare-migration.svg)

Instance boots via cloud-init: create swap -> install Docker + cloudflared -> fetch runtime secrets from SSM -> mount EBS volume -> deploy scripts -> start vaultwarden (Docker) + Cloudflare Tunnel (native systemd). Cloudflare Tunnel proxies HTTPS + SSH -- no public IPv4 needed.

## Prerequisites

- [OpenTofu](https://opentofu.org/) installed
- AWS CLI configured (see [Authentication](#authentication) below)
- Cloudflare account (free tier) with:
  - API token (Zone:DNS, Tunnel, R2, Access permissions)
  - Account ID
  - Zone ID for your domain
- R2 API credentials with `Object Read & Write` permission on the `bitwarden-backups` bucket

## Authentication

### AWS

This project uses temporary session tokens via AWS STS with MFA. Long-lived IAM credentials are never used directly.

**1. Create IAM user with MFA**

Create an IAM user with programmatic access. Assign a virtual MFA device.
Attach this policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": ["sts:GetSessionToken", "iam:ListMFADevices"],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
```

**2. Configure AWS CLI profiles**

`~/.aws/config`:

```ini
[default]

[profile temp]
region = eu-north-1
```

`~/.aws/credentials`:

```ini
[default]

[temp]
aws_access_key_id = AKIAXXXXXXXXXXXXXXXX
aws_secret_access_key = ...
```

The `temp` profile stores your long-lived IAM credentials. The `default` profile gets temporary session tokens written by the script below.

**3. Generate temporary credentials**

```bash
./scripts/aws-login.sh <iam-username> <mfa-code>
```

**4. Verify**

```bash
aws sts get-caller-identity
```

All tools (tofu, aws CLI) use the default profile automatically -- no `--profile` flag needed.

See [scripts/README.md](scripts/README.md) for full details.

### Cloudflare

See section [Get Cloudflare credentials](#2-get-cloudflare-credentials) below.

## Secrets Setup

### 1. Get Cloudflare credentials

You need four Cloudflare credentials for `terraform.tfvars`:

**Cloudflare API Token:**

1. Log in to Cloudflare dashboard, go to My Profile, then API Tokens
2. Create Token, use template "Edit Cloudflare Workers" (or create custom)
3. Required permissions:
   - **Account-level:**
     - `Cloudflare Tunnel:Edit`
     - `Workers R2 Storage:Edit`
     - `Access: Apps and Policies:Edit`
   - **Zone-level (select your domain):**
     - `DNS:Edit`
     - `Zone Settings:Edit`
     - `Single Redirect:Edit`
     - `Transform Rules:Edit`
4. Copy the token (shown once)

**Cloudflare Account ID:**

Found in Cloudflare dashboard right sidebar under "API", labeled Account ID.

**Cloudflare Zone ID:**

Select your domain in Cloudflare dashboard, go to Overview, find Zone ID in the right sidebar.

**R2 API Credentials:**

Separate token used only for backups. Scoped to R2 only, not the main API token above.

1. Cloudflare dashboard -> Storage & databases -> R2 Object Storage -> Overview -> API Tokens {} Manage
2. Create **Account API token** with `Object Read & Write` permission
3. Set scope to **Apply to all buckets in this account (including newly created buckets)**
   -- the `bitwarden-backups` bucket doesn't exist yet (tofu creates it). Once deployed, edit the token and restrict scope to `bitwarden-backups` only.
4. Copy Access Key ID and Secret Access Key

**Tunnel secret:**

Managed by tofu (`random_bytes`), stored in SSM as `/bitwarden/tunnel-secret` (SecureString) and fetched at instance boot before cloudflared starts. It also exists plaintext in Terraform state (`random_bytes` + tunnel resources) -- unavoidable for a Terraform-managed tunnel. Instance user-data carries no secret.

### 2. Create terraform.tfvars (gitignored)

Create `terraform.tfvars` in the project root:

```hcl
domain                = "vaultwarden.yourdomain.com"
cloudflare_api_token  = "<your-api-token>"
cloudflare_account_id = "<your-account-id>"
cloudflare_zone_id    = "<your-zone-id>"
ssh_public_key        = "<content-of-~/.ssh/id_ed25519.pub>"
ssh_allowed_ips       = ["<your-public-ip>/32"]
env_content           = <<EOF
DOMAIN=<your-domain>
R2_ACCESS_KEY_ID=<your-r2-access-key-id>
R2_SECRET_ACCESS_KEY=<your-r2-secret-access-key>
R2_ENDPOINT_URL=https://<your-account-id>.r2.cloudflarestorage.com
VAULTWARDEN_ADMIN_TOKEN=<generate-a-strong-random-token>
EOF
```

Generate the admin token:

```bash
openssl rand -base64 48
```

To find your public IP:

```bash
curl -s ifconfig.me
```

Include any additional IPs or CIDR ranges you want to allow SSH access:

```hcl
ssh_allowed_ips = ["203.0.113.1/32", "198.51.100.0/24"]
```

> `terraform.tfvars` is in `.gitignore` -- it will never be committed. The `env_content` value is stored in AWS SSM Parameter Store as a SecureString -- no local encryption files needed.

### 3. Deploy

```bash
tofu init
tofu plan -var-file=terraform.tfvars
tofu apply -var-file=terraform.tfvars
```

No age key needed. All secrets (R2 credentials, admin token) are stored directly in SSM via the `env_content` variable.

## SSH Access

### Primary: Cloudflare Tunnel SSH

```bash
cloudflared access ssh --hostname ssh.example.com
```

- Free (up to 50 users)
- Access controlled by `var.ssh_allowed_ips` (IP ranges in terraform.tfvars)
- No AWS dependency

### Fallback: SSM Session Manager

```bash
aws ssm start-session --target <instance-id>
```

- IAM-based auth
- Requires `AmazonSSMManagedInstanceCore` on instance role

## Bootstrap Flow

On instance launch, cloud-init runs `data/user-data.sh`:

1. Create 1GB swap file (t4g.nano needs it for dnf / installs)
2. Enable SSM Agent dual-stack (required for IPv6-only instances)
3. Install Docker + cloudflared (native, from cloudflared RPM repo)
4. Fetch runtime secrets from SSM (`/bitwarden/env` SecureString) -- uses dual-stack AWS endpoint
5. Write cloudflared tunnel credentials + ingress rules
6. Start cloudflared as a systemd service
7. Discover and format EBS volume, mount at `/data/`
8. Create `/data/vaultwarden` and `/data/scripts` directories
9. Deploy backup, restore, and spot termination scripts to `/data/scripts/`
10. Start spot-termination-notifier as a systemd service
11. Start vaultwarden via `docker run`

All network-dependent operations use exponential backoff retry (up to 5 attempts).

## Variables

See `variables.tf` for defaults.

### In terraform.tfvars (gitignored)

| Variable                | Description                                            |
| ----------------------- | ------------------------------------------------------ |
| `domain`                | Vaultwarden domain                                     |
| `cloudflare_api_token`  | Cloudflare API token                                   |
| `cloudflare_account_id` | Cloudflare account ID                                  |
| `cloudflare_zone_id`    | Cloudflare zone ID for the domain                      |
| `ssh_public_key`        | SSH public key for EC2 access                          |
| `ssh_allowed_ips`       | IP ranges allowed to SSH                               |
| `env_content`           | Runtime .env content (stored in SSM SecureString)      |

### In env_content (SSM SecureString)

| Variable                  | Description                                                  |
| ------------------------- | ------------------------------------------------------------ |
| `DOMAIN`                  | Vaultwarden domain (must match `domain` in terraform.tfvars) |
| `R2_ACCESS_KEY_ID`        | R2 API access key                                            |
| `R2_SECRET_ACCESS_KEY`    | R2 API secret key                                            |
| `R2_ENDPOINT_URL`         | R2 S3-compatible endpoint URL                                |
| `VAULTWARDEN_ADMIN_TOKEN` | Admin panel token (optional)                                 |

### Non-sensitive (in repo)

| Variable              | Default        | Description                           |
| --------------------- | -------------- | ------------------------------------- |
| `name`                | `"bitwarden"`  | Resource name prefix                  |
| `instance_types`      | `["t4g.nano","t4g.micro"]` | Spot instance types |
| `use_existing_vpc`    | `false`        | Use existing VPC by ID                |
| `existing_vpc_id`     | `""`           | VPC ID when use_existing_vpc=true     |
| `existing_subnet_ids` | `[]`           | Subnet IDs when use_existing_vpc=true |
| `tags`                | `{}`           | Resource tags                         |
| `aws_region`          | `"eu-north-1"` | AWS region (eu-north-1 is cheaper)    |

Caveats:
- `instance_types` are all passed as `mixed_instances_policy` overrides (100% spot); AWS selects the available/cheapest and falls back across types.
- `existing_subnet_ids` must be public (IPv6-capable); there is no NAT gateway.
- The ASG and EBS volume are pinned to a single AZ. Multi-type spot fallback helps within that AZ but not if the whole AZ lacks capacity.

## Migration from v1

This project was redesigned from the v1 setup (S3 + Traefik + Docker Compose + MariaDB). The migration switches from MariaDB to SQLite and replaces S3 with R2, removing `iam.tf`, `s3.tf`, `network.tf`, and `locals.tf`.

**Breaking change -- data loss risk.** Running `terraform apply` on existing state will schedule destruction of old S3 bucket, IAM roles, and network resources. A migration plan that includes `terraform state rm` for deleted resources before applying is required if migrating existing state.

For new deployments (no existing state), no action needed.

## Outputs

| Output               | Description                     |
| -------------------- | ------------------------------- |
| `url`                | `https://<domain>`              |
| `iam_role_name`      | Instance IAM role name          |
| `sg_id`              | Security group ID               |
| `volume_id`          | EBS volume ID                   |
| `r2_backup_bucket`   | R2 backup bucket name (resides in EU/WEUR for data residency)           |
| `tunnel_id`          | Cloudflare tunnel ID            |

## Data Reference

### Instance filesystem

| Path                              | Contents                                           |
| --------------------------------- | -------------------------------------------------- |
| `/data/vaultwarden/`              | Vaultwarden SQLite database + attachments (EBS)    |
| `/data/scripts/backup.sh`         | Backup script -- stops vaultwarden, tars to R2      |
| `/data/scripts/restore.sh`        | Restore script -- download from R2, extract         |
| `/data/scripts/r2-config.sh`      | Shared R2 config loader -- sourced by backup/restore |
| `/data/scripts/AWS_SpotTerminationNotifier.sh` | Graceful stop on spot termination     |
| `/etc/vaultwarden/.env`           | Runtime environment (from SSM)                     |
| `/etc/cloudflared/credentials.json` | Cloudflare tunnel credentials (template-substituted) |
| `/etc/cloudflared/config.yml`     | Cloudflare tunnel ingress rules                    |
| `/etc/systemd/system/spot-termination-notifier.service` | Spot term handler systemd unit |

### Backup naming

Backups are stored in R2 as `s3://bitwarden-backups/<YYYYMMDD-HHMMSS>-bitwarden-backup.tar.gz`. Restore from a specific timestamp:

```bash
/data/scripts/restore.sh 20260101-120000
```

Or restore from the latest backup automatically:

```bash
/data/scripts/restore.sh --latest
```

The `--latest` mode is also called automatically during instance bootstrap if the EBS volume is empty (e.g., new deploy or replaced volume).

List available backups:

```bash
aws s3 ls s3://bitwarden-backups/ --endpoint-url <R2_ENDPOINT_URL>
```

## Cost (~$1.86/month)

| Item                           | Cost             |
| ------------------------------ | ---------------- |
| EC2 spot t4g.nano (eu-north-1) | ~$1.46           |
| EBS gp3 5GB                    | $0.40            |
| R2 storage (<5GB)              | $0 (free tier)   |
| Cloudflare DNS + Tunnel        | $0 (free tier)   |
| Data transfer out              | ~$0              |
| Public IPv4                    | $0               |
| **Total**                      | **~$1.86/month** |

Cost does not change after AWS free tier expires -- none of our costs depend on it.
