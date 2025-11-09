/*
 * Security Group Models Module - Input Variables
 * 
 * This module creates template security groups for AWS Firewall Manager policies.
 * Variables are organized by the security group model they configure.
 */

# ============================================================================
# Infrastructure Configuration
# ============================================================================

variable "vpc_id" {
  description = "VPC ID where the security group models will be created"
  type        = string
  
  validation {
    condition     = can(regex("^vpc-", var.vpc_id))
    error_message = "VPC ID must be a valid VPC identifier starting with 'vpc-'."
  }
}

# ============================================================================
# Security Group Model Control
# ============================================================================

variable "create_golden" {
  description = "Whether to create the Golden baseline security group model"
  type        = bool
}

variable "create_allow_model" {
  description = "Whether to create the Allow Model security group (for Content Audit ALLOW policy)"
  type        = bool
}

variable "create_deny_model" {
  description = "Whether to create the Deny Model security group (for Content Audit DENY policy)"
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
    Whether the Golden SG should have default deny egress behavior.
    When true, only specified egress ports/CIDRs are explicitly allowed.
    When false, all egress traffic is allowed (AWS default behavior).
  EOF
  type        = bool
}

variable "golden_allowed_egress_cidrs" {
  description = <<-EOF
    List of CIDR blocks allowed for egress from the Golden security group.
    Only used when golden_default_deny_egress is false.
    Example: ["0.0.0.0/0", "10.0.0.0/8"]
  EOF
  type        = list(string)
}

variable "golden_allowed_egress_ports" {
  description = <<-EOF
    List of ports (as strings) allowed for egress from the Golden security group.
    Only the first port in the list is currently used due to implementation limitation.
    Common ports: ["80", "443", "53"]
  EOF
  type        = list(string)
}

# ============================================================================
# Allow Model Security Group Configuration
# ============================================================================

variable "allow_model_sg_name" {
  description = "Name for the Allow Model security group"
  type        = string
}

variable "allow_http_from_internet" {
  description = <<-EOF
    Whether to include HTTP/HTTPS rules from the internet (0.0.0.0/0 and ::/0)
    in the Allow Model security group. Typically enabled for web-facing applications.
  EOF
  type        = bool
}

variable "alb_security_group_id" {
  description = <<-EOF
    Security Group ID of an Application Load Balancer. If provided, the Allow Model
    will include rules allowing traffic from this ALB SG to application ports (8080).
  EOF
  type        = string
}

variable "app_security_group_id" {
  description = <<-EOF
    Security Group ID of an application tier. If provided, the Allow Model
    will include rules allowing traffic from this app SG to database ports.
  EOF
  type        = string
}

variable "app_to_db_port" {
  description = <<-EOF
    Port number for application to database communication in the Allow Model.
    Common values: 3306 (MySQL), 5432 (PostgreSQL), 1433 (SQL Server)
  EOF
  type        = number
}

# ============================================================================
# Deny Model Security Group Configuration
# ============================================================================

variable "deny_model_sg_name" {
  description = "Name for the Deny Model security group"
  type        = string
}

variable "create_deny_model_sg_name" {
  description = "Alternative name parameter for Deny Model security group (legacy compatibility)"
  type        = string
}

variable "deny_admin_ports" {
  description = <<-EOF
    List of administrative ports that should be flagged when exposed to the internet.
    The Deny Model SG will include rules for these ports from 0.0.0.0/0 and ::/0.
    Common admin ports: [22, 3389, 3306, 5432, 1433, 27017, 6379]
  EOF
  type        = list(number)
}
