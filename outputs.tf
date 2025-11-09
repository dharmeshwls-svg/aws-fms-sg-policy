/*
 * AWS Firewall Manager Security Group Policy - Outputs
 * 
 * This file defines outputs that expose key resource identifiers and information
 * from the deployed security group models and FMS policies.
 */

# ============================================================================
# Security Group Model Outputs
# ============================================================================

output "golden_sg_id" {
  description = <<-EOF
    Security Group ID of the Golden baseline security group.
    This SG is attached to all resources via FMS Common SG policy and provides
    baseline security controls across the organization.
  EOF
  value       = module.sg_models.golden_sg_id
}

output "allow_model_sg_id" {
  description = <<-EOF
    Security Group ID of the Allow Model security group.
    This SG serves as a template for the FMS Content Audit ALLOW policy,
    defining acceptable traffic patterns that should be allowed.
  EOF
  value       = module.sg_models.allow_sg_id
}

output "deny_model_sg_id" {
  description = <<-EOF
    Security Group ID of the Deny Model security group.
    This SG serves as a template for the FMS Content Audit DENY policy,
    defining traffic patterns that should be blocked or flagged for review.
  EOF
  value       = module.sg_models.deny_model_sg_id
}
