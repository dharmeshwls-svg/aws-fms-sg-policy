/*
 * AWS Firewall Manager Security Group Policies Module
 * 
 * This module creates four types of AWS Firewall Manager policies to enforce
 * security group compliance across an AWS Organization:
 * 
 * 1. Common SG Policy: Automatically attaches a baseline security group to all resources
 * 2. Content Audit ALLOW: Monitors and allows specific traffic patterns
 * 3. Content Audit DENY: Monitors and blocks risky traffic patterns  
 * 4. Usage Audit: Automatically cleans up unused and redundant security groups
 * 
 * REQUIREMENTS:
 * - AWS Organizations enabled with delegated FMS administrator account
 * - This module must be deployed from the FMS administrator account
 * - Appropriate IAM permissions for FMS operations
 */

# ============================================================================
# Common Security Group Policy (Baseline Attachment)
# ============================================================================
# Automatically attaches the Golden security group to all network interfaces
# across the organization. This provides baseline security controls.

resource "aws_fms_policy" "common_sg" {
  name = "CommonSecurityGroupBaseLine"
  
  # Policy configuration
  remediation_enabled         = true   # Automatically remediate non-compliant resources
  delete_all_policy_resources = false  # Keep resources when policy is deleted
  exclude_resource_tags       = false  # Apply to all resources regardless of tags

  # Target resource type for this policy
  resource_type = "AWS::EC2::NetworkInterface"

  # Organization scope - which OUs this policy applies to
  include_map {
    orgunit = var.org_ou_ids
  }

  # Policy-specific configuration
  security_service_policy_data {
    type = "SECURITY_GROUPS_COMMON"
    managed_service_data = jsonencode({
      type                            = "SECURITY_GROUPS_COMMON"
      revertManualSecurityGroupChanges = true  # Prevent manual changes to attached SG
      securityGroups = [
        { id = var.golden_sg_id }  # The baseline security group to attach
      ]
    })
  }
}

# ============================================================================
# Content Audit ALLOW Policy
# ============================================================================
# Monitors security groups and flags those that DON'T match allowed patterns.
# Uses the Allow Model SG as a template for acceptable traffic patterns.

resource "aws_fms_policy" "content_allow" {
  name = "ContentAudit-ALLOW-Baseline"
  
  # Policy configuration
  remediation_enabled         = true
  delete_all_policy_resources = false
  exclude_resource_tags       = false

  # Target EC2 instances for content auditing
  resource_type = "AWS::EC2::Instance"
  
  # Organization scope
  include_map {
    orgunit = var.org_ou_ids
  }

  # Policy-specific configuration for content auditing
  security_service_policy_data {
    type = "SECURITY_GROUPS_CONTENT_AUDIT"
    managed_service_data = jsonencode({
      type                = "SECURITY_GROUPS_CONTENT_AUDIT"
      securityGroupAction = { type = "ALLOW" }  # Flag resources that DON'T match this pattern
      securityGroups      = [{ id = var.allow_model_sg_id }]  # Template SG defining allowed patterns
    })
  }
}

# ============================================================================
# Content Audit DENY Policy  
# ============================================================================
# Monitors security groups and flags those that DO match prohibited patterns.
# Uses the Deny Model SG as a template for traffic patterns to block.

resource "aws_fms_policy" "content_deny" {
  name = "ContentAudit-DENY-WorldOpen-AdminPorts"
  
  # Policy configuration
  remediation_enabled         = true
  delete_all_policy_resources = false
  exclude_resource_tags       = false

  # Target EC2 instances for content auditing
  resource_type = "AWS::EC2::Instance"
  
  # Organization scope
  include_map {
    orgunit = var.org_ou_ids
  }

  # Policy-specific configuration for prohibited pattern detection
  security_service_policy_data {
    type = "SECURITY_GROUPS_CONTENT_AUDIT"
    managed_service_data = jsonencode({
      type                = "SECURITY_GROUPS_CONTENT_AUDIT"
      securityGroupAction = { type = "DENY" }  # Flag resources that DO match this pattern
      securityGroups      = [{ id = var.deny_model_sg_id }]  # Template SG defining prohibited patterns
    })
  }
}

# ============================================================================
# Usage Audit Policy (Cleanup)
# ============================================================================
# Automatically identifies and optionally deletes unused and redundant 
# security groups to reduce management overhead and security risk.

resource "aws_fms_policy" "usage_audit" {
  name = "UsageAudit-Cleanup"
  
  # Policy configuration
  remediation_enabled         = true
  delete_all_policy_resources = false
  exclude_resource_tags       = false

  # Target EC2 instances for usage auditing
  resource_type = "AWS::EC2::Instance"
  
  # Organization scope
  include_map {
    orgunit = var.org_ou_ids
  }

  # Policy-specific configuration for usage auditing and cleanup
  security_service_policy_data {
    type = "SECURITY_GROUPS_USAGE_AUDIT"
    managed_service_data = jsonencode({
      type                            = "SECURITY_GROUPS_USAGE_AUDIT"
      deleteUnusedSecurityGroups      = true   # Automatically delete unused SGs
      coalesceRedundantSecurityGroups = true   # Merge redundant SGs
      optionalDelayForUnusedInMinutes = var.usage_audit_unused_delay_minutes  # Grace period before deletion
    })
  }
}
