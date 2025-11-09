/*
 * AWS Firewall Manager Policies Module - Outputs
 * 
 * This file exposes information about the created FMS policies for monitoring
 * and integration with other systems.
 */

# ============================================================================
# FMS Policy Resource Identifiers
# ============================================================================

output "fms_common_policy_id" {
  description = <<-EOF
    AWS Firewall Manager policy ID for the Common Security Group policy.
    This policy automatically attaches the Golden SG to all network interfaces.
  EOF
  value       = aws_fms_policy.common_sg.id
}

output "fms_allow_policy_id" {
  description = <<-EOF
    AWS Firewall Manager policy ID for the Content Audit ALLOW policy.
    This policy flags security groups that don't match allowed patterns.
  EOF
  value       = aws_fms_policy.content_allow.id
}

output "fms_deny_policy_id" {
  description = <<-EOF
    AWS Firewall Manager policy ID for the Content Audit DENY policy.
    This policy flags security groups that match prohibited patterns.
  EOF
  value       = aws_fms_policy.content_deny.id
}

output "fms_usage_policy_id" {
  description = <<-EOF
    AWS Firewall Manager policy ID for the Usage Audit policy.
    This policy automatically cleans up unused and redundant security groups.
  EOF
  value       = aws_fms_policy.usage_audit.id
}

# ============================================================================
# Policy Summary Information
# ============================================================================

output "policy_summary" {
  description = "Summary of all created FMS policies"
  value = {
    common_sg_policy = {
      id   = aws_fms_policy.common_sg.id
      name = aws_fms_policy.common_sg.name
      type = "SECURITY_GROUPS_COMMON"
    }
    content_allow_policy = {
      id   = aws_fms_policy.content_allow.id
      name = aws_fms_policy.content_allow.name
      type = "SECURITY_GROUPS_CONTENT_AUDIT_ALLOW"
    }
    content_deny_policy = {
      id   = aws_fms_policy.content_deny.id
      name = aws_fms_policy.content_deny.name
      type = "SECURITY_GROUPS_CONTENT_AUDIT_DENY"
    }
    usage_audit_policy = {
      id   = aws_fms_policy.usage_audit.id
      name = aws_fms_policy.usage_audit.name
      type = "SECURITY_GROUPS_USAGE_AUDIT"
    }
  }
}
