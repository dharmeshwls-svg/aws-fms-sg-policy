# AWS Firewall Manager Security Group Policy

A comprehensive Terraform configuration for implementing organization-wide security group compliance using AWS Firewall Manager (FMS). This solution automatically enforces security group standards, monitors for violations, and maintains security hygiene across your entire AWS Organization.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     AWS Organization                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐                     │
│  │   Account A     │    │   Account B     │    ...              │
│  │                 │    │                 │                     │
│  │ ┌─────────────┐ │    │ ┌─────────────┐ │                     │
│  │ │Golden SG    │ │    │ │Golden SG    │ │ <- Auto-attached    │
│  │ │(Baseline)   │ │    │ │(Baseline)   │ │                     │
│  │ └─────────────┘ │    │ └─────────────┘ │                     │
│  │                 │    │                 │                     │
│  │ ┌─────────────┐ │    │ ┌─────────────┐ │                     │
│  │ │App Security │ │    │ │App Security │ │ <- Monitored        │
│  │ │Groups       │ │    │ │Groups       │ │                     │
│  │ └─────────────┘ │    │ └─────────────┘ │                     │
│  └─────────────────┘    └─────────────────┘                     │
└─────────────────────────────────────────────────────────────────┘
                                │
                                │ FMS Policies Monitor & Enforce
                                │
┌─────────────────────────────────────────────────────────────────┐
│              Firewall Manager Admin Account                     │
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   Golden SG     │  │  Allow Model    │  │  Deny Model     │  │
│  │   (Template)    │  │  SG (Template)  │  │  SG (Template)  │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
│            │                    │                    │          │
│            │                    │                    │          │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │Common SG Policy │  │Content Audit    │  │Content Audit    │  │
│  │(Attach Golden)  │  │ALLOW Policy     │  │DENY Policy      │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
│                                                                 │
│  ┌─────────────────┐                                            │
│  │Usage Audit      │                                            │
│  │Policy (Cleanup) │                                            │
│  └─────────────────┘                                            │
└─────────────────────────────────────────────────────────────────┘
```

## 🚀 Features

### Security Group Models
- **Golden SG**: Baseline security group automatically attached to all resources
- **Allow Model SG**: Template defining acceptable traffic patterns
- **Deny Model SG**: Template defining prohibited traffic patterns

### AWS Firewall Manager Policies
1. **Common Security Group Policy**: Automatically attaches baseline security group to all network interfaces
2. **Content Audit ALLOW Policy**: Flags resources that don't match approved traffic patterns
3. **Content Audit DENY Policy**: Flags resources that match prohibited traffic patterns (e.g., admin ports open to internet)
4. **Usage Audit Policy**: Automatically identifies and removes unused/redundant security groups

### Compliance Monitoring
- Continuous monitoring across all AWS accounts in your organization
- Automatic remediation capabilities
- Granular reporting and alerting
- Prevention of manual security group modifications

## 📋 Prerequisites

### AWS Organization Setup
1. **AWS Organizations** enabled with all accounts joined
2. **Delegated FMS Administrator** account configured
3. **AWS Config** enabled in all target accounts and regions
4. **Service-Linked Roles** for AWS Firewall Manager

### Permissions Required

#### FMS Administrator Account Setup
The FMS administrator account must have:
1. **Delegated FMS Administrator** status in AWS Organizations
2. **Service-Linked Roles** for AWS Firewall Manager (auto-created)

#### Terraform User/Role Permissions
The IAM user or role running Terraform needs the following permissions:

**Option 1: Use AWS Managed Policies**
- `arn:aws:iam::aws:policy/FMSServiceRolePolicy`
- `arn:aws:iam::aws:policy/ConfigServiceRole`

**Option 2: Custom IAM Policy (Minimal Permissions)**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "fms:PutPolicy",
                "fms:GetPolicy", 
                "fms:DeletePolicy",
                "fms:ListPolicies",
                "fms:GetAdminAccount",
                "fms:AssociateAdminAccount",
                "fms:DisassociateAdminAccount",
                "fms:GetComplianceDetail",
                "fms:GetViolationDetails"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "organizations:ListAccounts",
                "organizations:DescribeOrganization",
                "organizations:DescribeOrganizationalUnit",
                "organizations:DescribeAccount",
                "organizations:ListChildren",
                "organizations:ListOrganizationalUnitsForParent"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:AuthorizeSecurityGroupEgress", 
                "ec2:CreateSecurityGroup",
                "ec2:DeleteSecurityGroup",
                "ec2:DescribeSecurityGroups",
                "ec2:RevokeSecurityGroupIngress",
                "ec2:RevokeSecurityGroupEgress",
                "ec2:DescribeVpcs",
                "ec2:CreateTags"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "config:DescribeConfigurationRecorders",
                "config:DescribeDeliveryChannels",
                "config:DescribeConfigRules",
                "config:GetComplianceDetailsByConfigRule",
                "config:GetComplianceDetailsByResource"
            ],
            "Resource": "*"
        }
    ]
}
```

#### Quick Fix for Current Error
To resolve the immediate `fms:PutPolicy` error:

**Option A: Use the automated setup script**
```bash
# Run the interactive IAM setup script
./setup-iam.sh
```

**Option B: Manual setup**
```bash
# Attach the FMS service role policy to your terraform user
aws iam attach-user-policy \
    --user-name terraform-user \
    --policy-arn arn:aws:iam::aws:policy/FMSServiceRolePolicy

# OR create and attach the minimal custom policy
aws iam create-policy \
    --policy-name TerraformFMSPolicy \
    --policy-document file://terraform-fms-policy.json

aws iam attach-user-policy \
    --user-name terraform-user \
    --policy-arn arn:aws:iam::817222001188:policy/TerraformFMSPolicy
```

### Infrastructure
- **VPC** already exists in the target region
- **Terraform** v1.7 or later
- **AWS Provider** v5.0 or later

## 🛠️ Installation and Usage

### 1. Clone Repository
```bash
git clone <repository-url>
cd aws-fms-sg-policy
```

### 2. Configure Variables
Create or modify `prod.tfvars`:

```hcl
# Core Infrastructure
region = "Provide region"
vpc_id = "Provide VPC ID "

# Organization Configuration
create_fms_policies = true
org_ou_ids = ["Provide OU Organization ID"]

# Security Group Models
create_golden      = true
create_allow_model = true
create_deny_model  = true

# Golden SG Configuration
golden_sg_name             = "golden-baseline-sg"
golden_default_deny_egress = true
golden_allowed_egress_ports = ["443", "80"]
golden_allowed_egress_cidrs = ["0.0.0.0/0"]

# Allow Model Configuration
allow_model_sg_name      = "fms-allow-model"
allow_http_from_internet = true
# Optional: Reference existing security groups
# alb_security_group_id    = "sg-alb12345"
# app_security_group_id    = "sg-app12345"
# app_to_db_port           = 3306

# Deny Model Configuration
deny_model_sg_name = "fms-deny-model"
deny_admin_ports   = [22, 3389, 3306, 5432, 1433]

# Usage Audit Configuration
usage_audit_unused_delay_minutes = 43200  # 30 days
```

### 3. Deploy Infrastructure
```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var-file=prod.tfvars

# Apply configuration
terraform apply -var-file=prod.tfvars
```

### 4. Verify Deployment
```bash
# Check created resources
terraform output

# Verify in AWS Console:
# - Firewall Manager > Security policies
# - EC2 > Security groups
```

## 📁 Project Structure

```
aws-fms-sg-policy/
├── main.tf                    # Main configuration and module calls
├── variables.tf               # Input variable definitions
├── outputs.tf                 # Output definitions
├── providers.tf               # Provider configuration
├── prod.tfvars                # Production configuration values
├── setup-iam.sh              # Interactive IAM permissions setup script
├── terraform-fms-policy.json  # Custom IAM policy for Terraform FMS access
├── README.md                  # This documentation
├── LICENSE                    # MIT License
│
├── modules/
│   ├── fms_policies/         # AWS Firewall Manager policies module
│   │   ├── main.tf           # FMS policy resources
│   │   ├── variables.tf      # Module input variables  
│   │   └── outputs.tf        # Module outputs
│   │
│   └── sg_models/            # Security group models module
│       ├── main.tf           # Security group resources
│       ├── variables.tf      # Module input variables
│       └── output.tf         # Module outputs
```

## 🔧 Configuration Reference

### Core Variables

| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `region` | string | AWS region for deployment | - |
| `vpc_id` | string | VPC ID where SGs are created | - |
| `org_ou_ids` | list(string) | Organization Unit IDs for FMS policies | `[]` |
| `create_fms_policies` | bool | Whether to create FMS policies | - |

### Golden Security Group

| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `create_golden` | bool | Create Golden baseline SG | - |
| `golden_sg_name` | string | Name for Golden SG | - |
| `golden_default_deny_egress` | bool | Use default deny for egress | - |
| `golden_allowed_egress_ports` | list(string) | Allowed egress ports | - |
| `golden_allowed_egress_cidrs` | list(string) | Allowed egress CIDRs | `["0.0.0.0/0"]` |

### Allow Model Security Group

| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `create_allow_model` | bool | Create Allow Model SG | - |
| `allow_model_sg_name` | string | Name for Allow Model SG | - |
| `allow_http_from_internet` | bool | Allow HTTP/S from internet | - |
| `alb_security_group_id` | string | ALB SG ID for app tier rules | `""` |
| `app_security_group_id` | string | App SG ID for DB tier rules | `""` |
| `app_to_db_port` | number | Application to database port | `3306` |

### Deny Model Security Group

| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `create_deny_model` | bool | Create Deny Model SG | - |
| `deny_model_sg_name` | string | Name for Deny Model SG | `""` |
| `deny_admin_ports` | list(number) | Admin ports to flag when exposed | `[22, 3389, 3306, 5432]` |

## 📊 Outputs

| Output | Description |
|--------|-------------|
| `golden_sg_id` | Security Group ID of Golden baseline SG |
| `allow_model_sg_id` | Security Group ID of Allow Model SG |
| `deny_model_sg_id` | Security Group ID of Deny Model SG |

## 🔍 Monitoring and Compliance

### AWS Config Rules
The FMS policies automatically create AWS Config rules to monitor compliance:
- Security group compliance status
- Policy violations and findings
- Remediation actions taken

### CloudWatch Integration
- FMS policy execution metrics
- Compliance score tracking
- Alert notifications for violations

### AWS Security Hub
All FMS findings are automatically sent to Security Hub for centralized security monitoring.

## 🚨 Important Considerations

### Deployment Account
- **MUST** be deployed from the AWS Organizations Firewall Manager administrator account
- Cannot be deployed from member accounts

### Regional Considerations  
- Deploy in each region where you need security group monitoring
- FMS policies are region-specific

### Existing Security Groups
- Common SG policy will attach Golden SG to existing resources
- Content audit policies will evaluate existing security groups
- Usage audit may identify existing unused security groups for cleanup

### Cost Implications
- AWS Config charges apply for configuration item recording
- FMS charges apply per policy per region
- Consider costs when deploying across multiple regions

## 🔧 Troubleshooting

### Common Issues

**Issue**: Terraform plan fails with provider errors
```bash
Error: Failed to query available provider packages
```
**Solution**: Verify AWS credentials and region configuration

**Issue**: FMS policy creation fails with AccessDeniedException
```bash
Error: AccessDeniedException: User: arn:aws:iam::817222001188:user/terraform-user 
is not authorized to perform: fms:PutPolicy
```
**Solution**: Attach FMS permissions to your Terraform user:
```bash
aws iam attach-user-policy \
    --user-name terraform-user \
    --policy-arn arn:aws:iam::aws:policy/FMSServiceRolePolicy
```

**Issue**: Invalid Organization ID
```bash
Error: InvalidParameterValue: Invalid Organization ID
```
**Solution**: Ensure you're deploying from the FMS administrator account and verify org_ou_ids

**Issue**: Security group references fail
```bash
Error: referenced_security_group_id is not expected
```
**Solution**: Verify security group IDs exist and are in the same VPC

### Validation Commands
```bash
# Verify AWS Organizations access
aws organizations describe-organization

# Check FMS administrator status
aws fms get-admin-account

# Verify AWS Config is enabled
aws configservice describe-configuration-recorders
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Additional Resources

- [AWS Firewall Manager Documentation](https://docs.aws.amazon.com/waf/latest/developerguide/fms-chapter.html)
- [AWS Config Rules Reference](https://docs.aws.amazon.com/config/latest/developerguide/managed-rules-by-aws-firewall-manager.html)
- [Security Group Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html)
- [AWS Organizations Setup Guide](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_getting-started.html)


For issues and questions:
- Create an issue in this repository
- Review AWS Firewall Manager documentation
- Check AWS Config service status in your region
