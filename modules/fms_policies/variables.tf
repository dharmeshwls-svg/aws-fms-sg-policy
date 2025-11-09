/*
 * AWS Firewall Manager Policies Module - Input Variables
 * 
 * This module requires security group IDs from the sg_models module
 * and organization configuration for policy deployment.
 */

# ============================================================================
# Organization Configuration
# ============================================================================

variable "org_ou_ids" {
  description = <<-EOF
    List of AWS Organizations Organizational Unit (OU) IDs where the FMS 
    policies will be applied. These should include the root OU or specific 
    OUs containing the accounts to be managed.
  EOF
  type        = list(string)
  
  validation {
    condition     = length(var.org_ou_ids) > 0
    error_message = "At least one Organization Unit ID must be provided."
  }
}

# ============================================================================
# Security Group Model References
# ============================================================================

variable "golden_sg_id" {
  description = <<-EOF
    Security Group ID of the Golden baseline security group.
    This will be attached to all resources via the FMS Common SG policy.
  EOF
  type        = string
  
  validation {
    condition     = can(regex("^sg-", var.golden_sg_id))
    error_message = "Golden SG ID must be a valid security group identifier starting with 'sg-'."
  }
}

variable "allow_model_sg_id" {
  description = <<-EOF
    Security Group ID of the Allow Model security group.
    This serves as a template for the FMS Content Audit ALLOW policy.
  EOF
  type        = string
  
  validation {
    condition     = can(regex("^sg-", var.allow_model_sg_id))
    error_message = "Allow Model SG ID must be a valid security group identifier starting with 'sg-'."
  }
}

variable "deny_model_sg_id" {
  description = <<-EOF
    Security Group ID of the Deny Model security group.
    This serves as a template for the FMS Content Audit DENY policy.
  EOF
  type        = string
  
  validation {
    condition     = can(regex("^sg-", var.deny_model_sg_id))
    error_message = "Deny Model SG ID must be a valid security group identifier starting with 'sg-'."
  }
}

# ============================================================================
# Policy Configuration
# ============================================================================

variable "usage_audit_unused_delay_minutes" {
  description = <<-EOF
    Number of minutes after which unused security groups are flagged for deletion
    by the FMS Usage Audit policy. Must be at least 60 minutes.
  EOF
  type        = number
  
  validation {
    condition     = var.usage_audit_unused_delay_minutes >= 60
    error_message = "Usage audit delay must be at least 60 minutes to prevent accidental deletions."
  }
}
