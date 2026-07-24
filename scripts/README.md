# aws-login

Generate temporary AWS credentials via STS with MFA. Credentials are valid for 12 hours.

## How it works

Two AWS CLI profiles are used:

- `temp` - holds long-lived IAM user credentials (never used directly)
- `default` - holds temporary session tokens (written by this script)

The long-lived credentials never leave your machine. All AWS API calls use the
default profile with temporary session tokens.

## IAM user prerequisites

The IAM user needs:

- MFA device assigned and enabled
- `sts:GetSessionToken` permission
- `iam:ListMFADevices` permission

Minimal IAM policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["sts:GetSessionToken", "iam:ListMFADevices"],
      "Resource": "*"
    }
  ]
}
```

## Initial AWS CLI configuration

`~/.aws/config`:

```ini
# Always be explicit when using profiles, thus leave the
# default profile empty for improved security.
[default]

[profile temp]
region = eu-north-1
```

`~/.aws/credentials`:

```ini
# Always be explicit when using profiles, thus leave the
# default profile empty for improved security.
[default]

[temp]
aws_access_key_id = AKIAXXXXXXXXXXXXXXXX
aws_secret_access_key = OJ4m6bw6YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY
```

The `temp` profile is your long-lived IAM user creds. The `default` profile is
auto-populated by the script with temporary session tokens (12h validity).

## Run the script

```bash
./scripts/aws-login.sh <iam-username> <mfa-code>
```

After running, `~/.aws/credentials` will look like:

```ini
[temp]
aws_access_key_id = AKIAXXXXXXXXXXXXXXXX
aws_secret_access_key = OJ4m6bw6YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY

[default]
aws_access_key_id = ASIA...
aws_secret_access_key = ...
aws_session_token = ...
```

## Verify

```bash
aws sts get-caller-identity
```

## Usage with tofu

```bash
tofu plan   # uses default profile automatically
```
