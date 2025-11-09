/*
 * Security Group Models Module - Outputs
 * 
 * This file exposes the Security Group IDs created by this module for use
 * in AWS Firewall Manager policies and other integrations.
 */

# ============================================================================
# Security Group Model Identifiers
# ============================================================================

output "golden_sg_id" {
  description = <<-EOF
    Security Group ID of the Golden baseline security group.
    This SG serves as a baseline template and is attached to all resources
    via the FMS Common Security Group policy.
    Returns null if create_golden is false.
  EOF
  value       = try(aws_security_group.golden[0].id, null)
}

output "allow_sg_id" {
  description = <<-EOF
    Security Group ID of the Allow Model security group.
    This SG serves as a template for the FMS Content Audit ALLOW policy,
    defining traffic patterns that should be considered acceptable.
    Returns null if create_allow_model is false.
  EOF
  value       = try(aws_security_group.allow_model[0].id, null)
}

output "deny_model_sg_id" {
  description = <<-EOF
    Security Group ID of the Deny Model security group.
    This SG serves as a template for the FMS Content Audit DENY policy,
    defining traffic patterns that should be flagged or blocked.
    Returns null if create_deny_model is false.
  EOF
  value       = try(aws_security_group.deny_model[0].id, null)
}

# ============================================================================
# Additional Security Group Information
# ============================================================================

output "security_group_summary" {
  description = "Summary of all created security group models"
  value = {
    golden = var.create_golden ? {
      id   = aws_security_group.golden[0].id
      name = aws_security_group.golden[0].name
      type = "Golden Baseline"
    } : null
    
    allow_model = var.create_allow_model ? {
      id   = aws_security_group.allow_model[0].id
      name = aws_security_group.allow_model[0].name
      type = "Allow Model Template"
    } : null
    
    deny_model = var.create_deny_model ? {
      id   = aws_security_group.deny_model[0].id
      name = aws_security_group.deny_model[0].name
      type = "Deny Model Template"
    } : null
  }
}
