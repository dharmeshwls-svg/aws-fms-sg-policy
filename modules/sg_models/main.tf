/*
 * Security Group Models Module
 * 
 * This module creates three types of security group "models" that serve as templates
 * for AWS Firewall Manager policies:
 * 
 * 1. Golden SG: Baseline security group attached to all resources
 * 2. Allow Model SG: Template defining acceptable traffic patterns
 * 3. Deny Model SG: Template defining prohibited traffic patterns
 * 
 * These security groups themselves don't directly protect traffic - they serve as
 * reference models for FMS policies to enforce organization-wide compliance.
 */

# ============================================================================
# Golden Security Group (Baseline Model)
# ============================================================================
# The Golden SG provides baseline security controls and is automatically
# attached to all network interfaces via FMS Common SG policy.

resource "aws_security_group" "golden" {
  count       = var.create_golden ? 1 : 0
  name        = var.golden_sg_name
  description = "Golden baseline security group for FMS common attachment policy"
  vpc_id      = var.vpc_id

  # Standard tags for identification and management
  tags = {
    Purpose       = "GoldenBaseline"
    ManagedBy     = "Terraform"
    SecurityModel = "Golden"
    Description   = "Baseline security group attached to all resources via FMS"
  }
}

# Optional explicit egress rules for Golden SG
# Only created when golden_default_deny_egress is false
# Note: There appears to be a typo in the original code - "lenth" should be "length"

resource "aws_vpc_security_group_egress_rule" "golden_egress" {
  # Create egress rules only if Golden SG exists and default deny is disabled
  for_each = var.create_golden && !var.golden_default_deny_egress ? {
    for idx, cidr in var.golden_allowed_egress_cidrs :
    "${idx}-${cidr}" => {
      cidr = cidr
      idx  = idx
    }
  } : {}

  security_group_id = aws_security_group.golden[0].id
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value.cidr
  
  # Use the first port from the allowed egress ports list
  # This could be enhanced to allow different ports per CIDR
  from_port = tonumber(element(var.golden_allowed_egress_ports, 0))
  to_port   = tonumber(element(var.golden_allowed_egress_ports, 0))
  
  description = "Golden SG - Allowed egress to ${each.value.cidr}"
}

# ============================================================================
# Allow Model Security Group
# ============================================================================
# This SG defines traffic patterns that SHOULD be allowed across the organization.
# The FMS Content Audit ALLOW policy will flag resources that DON'T match these patterns.

resource "aws_security_group" "allow_model" {
  count       = var.create_allow_model ? 1 : 0
  name        = var.allow_model_sg_name
  description = "Allow-list model security group for FMS Content Audit ALLOW policy"
  vpc_id      = var.vpc_id

  tags = {
    SecurityModel = "AllowModel"
    ManagedBy     = "Terraform"
    Description   = "Template for acceptable traffic patterns"
  }
}

# Internet-facing HTTP traffic (IPv4)
resource "aws_vpc_security_group_ingress_rule" "allow_model_http80_ipv4" {
  count             = var.create_allow_model && var.allow_http_from_internet ? 1 : 0
  security_group_id = aws_security_group.allow_model[0].id
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  description       = "Allow Model - HTTP from Internet (IPv4) for web-facing resources"
}

# Internet-facing HTTPS traffic (IPv4)
resource "aws_vpc_security_group_ingress_rule" "allow_model_http443_ipv4" {
  count             = var.create_allow_model && var.allow_http_from_internet ? 1 : 0
  security_group_id = aws_security_group.allow_model[0].id
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  description       = "Allow Model - HTTPS from Internet (IPv4) for web-facing resources"
}

# Internet-facing HTTP traffic (IPv6)
resource "aws_vpc_security_group_ingress_rule" "allow_model_http80_ipv6" {
  count             = var.create_allow_model && var.allow_http_from_internet ? 1 : 0
  security_group_id = aws_security_group.allow_model[0].id
  ip_protocol       = "tcp"
  cidr_ipv6         = "::/0"
  from_port         = 80
  to_port           = 80
  description       = "Allow Model - HTTP from Internet (IPv6) for web-facing resources"
}

# Internet-facing HTTPS traffic (IPv6)
resource "aws_vpc_security_group_ingress_rule" "allow_model_http443_ipv6" {
  count             = var.create_allow_model && var.allow_http_from_internet ? 1 : 0
  security_group_id = aws_security_group.allow_model[0].id
  ip_protocol       = "tcp"
  cidr_ipv6         = "::/0"
  from_port         = 443
  to_port           = 443
  description       = "Allow Model - HTTPS from Internet (IPv6) for web-facing resources"
}

# Application tier access from Application Load Balancer
# Only created when ALB security group ID is provided
resource "aws_vpc_security_group_ingress_rule" "allow_model_app_from_alb" {
  count                        = var.create_allow_model && var.alb_security_group_id != "" ? 1 : 0
  security_group_id            = aws_security_group.allow_model[0].id
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.alb_security_group_id
  from_port                    = 8080
  to_port                      = 8080
  description                  = "Allow Model - Application port access from ALB security group"
}

# Database tier access from Application tier
# Only created when App security group ID is provided
resource "aws_vpc_security_group_ingress_rule" "allow_model_db_from_app" {
  count                        = var.create_allow_model && var.app_security_group_id != "" ? 1 : 0
  security_group_id            = aws_security_group.allow_model[0].id
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.app_security_group_id
  from_port                    = var.app_to_db_port
  to_port                      = var.app_to_db_port
  description                  = "Allow Model - Database port access from application security group"
}

# ============================================================================
# Deny Model Security Group
# ============================================================================
# This SG defines traffic patterns that should be PROHIBITED across the organization.
# The FMS Content Audit DENY policy will flag resources that DO match these patterns.

resource "aws_security_group" "deny_model" {
  count       = var.create_deny_model ? 1 : 0
  name        = var.deny_model_sg_name
  description = "Deny-list model security group for FMS Content Audit DENY policy"
  vpc_id      = var.vpc_id

  tags = {
    SecurityModel = "DenyModel"
    ManagedBy     = "Terraform"
    Description   = "Template for prohibited traffic patterns"
  }
}

# Prohibited: Administrative ports open to the internet (IPv4)
# Creates one rule per administrative port for granular monitoring
resource "aws_vpc_security_group_ingress_rule" "deny_model_admin_world_ipv4" {
  for_each          = var.create_deny_model ? toset([for p in var.deny_admin_ports : tostring(p)]) : []
  security_group_id = aws_security_group.deny_model[0].id
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = tonumber(each.value)
  to_port           = tonumber(each.value)
  description       = "Deny Model - Administrative port ${each.value} open to Internet (IPv4) - PROHIBITED"
}

# Prohibited: Administrative ports open to the internet (IPv6)
# Creates one rule per administrative port for granular monitoring
resource "aws_vpc_security_group_ingress_rule" "deny_model_admin_world_ipv6" {
  for_each          = var.create_deny_model ? toset([for p in var.deny_admin_ports : tostring(p)]) : []
  security_group_id = aws_security_group.deny_model[0].id
  ip_protocol       = "tcp"
  cidr_ipv6         = "::/0"
  from_port         = tonumber(each.value)
  to_port           = tonumber(each.value)
  description       = "Deny Model - Administrative port ${each.value} open to Internet (IPv6) - PROHIBITED"
}
