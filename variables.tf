/*
 * AWS Firewall Manager Security Group Policy - Input Variables
 * 
 * This file defines all input variables for the AWS FMS Security Group
 * policy configuration. Variables are organized by functional area.
 */

# ============================================================================
# Core Infrastructure Variables
# ============================================================================

variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string

  validation {
    condition     = can(regex("^vpc-", var.vpc_id))
    error_message = "VPC ID must be a valid VPC identifier starting with 'vpc-'."
  }
}

variable "region" {
  description = "AWS region where resources will be deployed"
  type        = string
}

# ============================================================================
# AWS Organizations and FMS Configuration
# ============================================================================

variable "org_ou_ids" {
  description = <<-EOF
    List of AWS Organizations Organizational Unit (OU) IDs where FMS policies should be applied.
    These should be the root OU or specific OUs that contain the accounts you want to manage.
    Example: ["o-xspfq7zasv", "ou-root-123456789"]
  EOF
  type        = list(string)
  default     = []
}

variable "create_fms_policies" {
  description = <<-EOF
    Whether to create AWS Firewall Manager policies. Set to false if you only
    want to create the security group models without the FMS policies.
  EOF
  type        = bool
}

variable "usage_audit_unused_delay_minutes" {
  description = <<-EOF
    Number of minutes after which unused security groups are flagged for deletion
    by the FMS Usage Audit policy. Default is 30 days (43200 minutes).
  EOF
  type        = number
  default     = 43200

  validation {
    condition     = var.usage_audit_unused_delay_minutes >= 60
    error_message = "Usage audit delay must be at least 60 minutes."
  }
}

# ============================================================================
# Security Group Model Control Variables
# ============================================================================

variable "create_golden" {
  description = <<-EOF
    Whether to create the Golden baseline security group. This security group
    is attached to all resources via FMS Common SG policy.
  EOF
  type        = bool
}

variable "create_allow_model" {
  description = <<-EOF
    Whether to create the Allow Model security group. This serves as a template
    for allowed traffic patterns in FMS Content Audit ALLOW policy.
  EOF
  type        = bool
}

variable "create_deny_model" {
  description = <<-EOF
    Whether to create the Deny Model security group. This serves as a template
    for prohibited traffic patterns in FMS Content Audit DENY policy.
  EOF
  type        = bool
}

# ============================================================================
# Golden Security Group Configuration
# ============================================================================

variable "golden_sg_name" {
  description = "Name for the Golden baseline security group"
  type        = string
}

variable "golden_default_deny_egress" {
  description = <<-EOF
    Whether the Golden SG should have default deny egress rules. When true,
    only specified egress ports/CIDRs are allowed. When false, all egress is allowed.
  EOF
  type        = bool
}

variable "golden_allowed_egress_cidrs" {
  description = <<-EOF
    List of CIDR blocks allowed for egress from the Golden security group.
    Only used when golden_default_deny_egress is true.
  EOF
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "golden_allowed_egress_ports" {
  description = <<-EOF
    List of ports allowed for egress from the Golden security group.
    Common ports: 80 (HTTP), 443 (HTTPS), 53 (DNS)
  EOF
  type        = list(string)
  default     = ["80", "443"]
}

# ============================================================================
# Allow Model Security Group Configuration
# ============================================================================

variable "allow_model_sg_name" {
  description = "Name for the Allow Model security group used in FMS Content Audit ALLOW policy"
  type        = string
}

variable "allow_http_from_internet" {
  description = <<-EOF
    Whether to allow HTTP/HTTPS traffic from the internet (0.0.0.0/0) in the
    Allow Model security group. Typically used for web-facing resources.
  EOF
  type        = bool
}

variable "alb_security_group_id" {
  description = <<-EOF
    Security Group ID of an Application Load Balancer. If provided, the Allow Model SG
    will include rules allowing traffic from this ALB SG to application ports.
  EOF
  type        = string
  default     = ""
}

variable "app_security_group_id" {
  description = <<-EOF
    Security Group ID of application tier. If provided, the Allow Model SG
    will include rules allowing traffic from this app SG to database ports.
  EOF
  type        = string
  default     = ""
}

variable "app_to_db_port" {
  description = <<-EOF
    Port number for application to database communication.
    Common database ports: 3306 (MySQL), 5432 (PostgreSQL), 1433 (SQL Server)
  EOF
  type        = number
  default     = 3306

  validation {
    condition     = var.app_to_db_port > 0 && var.app_to_db_port <= 65535
    error_message = "Database port must be between 1 and 65535."
  }
}

# ============================================================================
# Deny Model Security Group Configuration
# ============================================================================

variable "deny_model_sg_name" {
  description = "Name for the Deny Model security group used in FMS Content Audit DENY policy"
  type        = string
  default     = ""
}

variable "create_deny_model_sg_name" {
  description = "Alternative name parameter for Deny Model security group (legacy compatibility)"
  type        = string
  default     = ""
}

variable "deny_admin_ports" {
  description = <<-EOF
    List of administrative ports that should be flagged when exposed to the internet.
    Common admin ports: 22 (SSH), 3389 (RDP), 5432 (PostgreSQL), 3306 (MySQL)
  EOF
  type        = list(number)
  default     = [22, 3389, 3306, 5432]

  validation {
    condition = alltrue([
      for port in var.deny_admin_ports : port > 0 && port <= 65535
    ])
    error_message = "All ports must be between 1 and 65535."
  }
}