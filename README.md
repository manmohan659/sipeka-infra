# SiPeKa Infrastructure

Infrastructure-as-Code and deployment workflows for the SiPeKa Employee Payroll Management System.

## Architecture

```
GitHub Actions (CI/CD)
    │
    ├── Nightly Build → Temp EC2 (smoke test) → ECR → QA EC2
    ├── RC Promotion  → Retag in ECR → RC EC2
    └── Triggered by  → Source repo merge / schedule / manual
```

## AWS Resources (Manual Setup - Day 1)

| Resource | Purpose |
|----------|---------|
| RDS MySQL | Production database |
| ECR | Container image registry (`sipeka-backend`, `sipeka-frontend`) |
| EC2 (QA) | QA testing environment |
| EC2 (RC) | Release Candidate environment (BONUS) |
| Route53 | DNS management |
| SSM Parameter Store | Secrets management |

## GitHub Secrets Required

| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | IAM user access key |
| `AWS_SECRET_ACCESS_KEY` | IAM user secret key |
| `AWS_ACCOUNT_ID` | AWS account number |
| `EC2_SSH_KEY` | PEM key for EC2 SSH access |
| `QA_EC2_HOST` | Public IP of QA EC2 |
| `RC_EC2_HOST` | Public IP of RC EC2 (BONUS) |
| `SG_ID` | Security Group ID for temp EC2 |
| `SUBNET_ID` | Subnet ID for temp EC2 |

## Scripts

| Script | Usage |
|--------|-------|
| `scripts/deploy.sh` | Manual deployment to an EC2 |
| `scripts/smoke-test.sh` | Run smoke tests against a host |
| `scripts/setup-ssl.sh` | Set up Let's Encrypt SSL |
| `scripts/setup-ssm-params.sh` | Configure SSM parameters |
| `scripts/ec2-userdata.sh` | EC2 bootstrap (Docker install) |

## SSL Setup

```bash
sudo ./scripts/setup-ssl.sh yourdomain.com your@email.com
```

Then update `nginx/nginx-ssl.conf` with your domain and restart the frontend container.
