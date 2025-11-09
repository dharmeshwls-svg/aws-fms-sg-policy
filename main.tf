/*
 * AWS Firewall Manager Security Group Policy
 * 
 * This Terraform configuration creates AWS Firewall Manager (FMS) policies
 * for security group compliance across an AWS Organization. It includes:
 * 
 * - Security Group Models: Creates baseline and audit security groups
 * - FMS Policies: Creates organization-wide security group policies
 * 
 * The configuration requires:
 * - AWS Organizations with delegated FMS admin account
 * - Proper IAM permissions for FMS operations
 * - VPC already created in the target region
 */

# ============================================================================
# Security Group Models Module
# ============================================================================
# Creates baseline security groups that serve as templates for FMS policies:
# - Golden SG: Baseline security group attached to all resources
# - Allow Model SG: Template for allowed traffic patterns
# - Deny Model SG: Template for traffic patterns to block/audit

module "sg_models" {
  source = "./modules/sg_models"

  # VPC Configuration
  vpc_id = var.vpc_id

  # Control which security group models to create
  create_golden      = var.create_golden
  create_allow_model = var.create_allow_model
  create_deny_model  = var.create_deny_model

  # Golden Security Group Configuration (Baseline)
  golden_sg_name              = var.golden_sg_name
  golden_default_deny_egress  = var.golden_default_deny_egress
  golden_allowed_egress_cidrs = var.golden_allowed_egress_cidrs
  golden_allowed_egress_ports = var.golden_allowed_egress_ports

  # Allow Model Security Group Configuration
  allow_model_sg_name      = var.allow_model_sg_name
  allow_http_from_internet = var.allow_http_from_internet
  alb_security_group_id    = var.alb_security_group_id
  app_security_group_id    = var.app_security_group_id
  app_to_db_port           = var.app_to_db_port

  # Deny Model Security Group Configuration
  deny_model_sg_name        = var.deny_model_sg_name
  create_deny_model_sg_name = var.create_deny_model_sg_name
  deny_admin_ports          = var.deny_admin_ports
}

# ============================================================================
# AWS Firewall Manager Policies Module
# ============================================================================
# Creates FMS policies for organization-wide security group compliance:
# - Common SG Policy: Attaches golden SG to all resources
# - Content Audit Allow: Monitors for allowed traffic patterns
# - Content Audit Deny: Monitors and blocks risky traffic patterns
# - Usage Audit: Cleans up unused and redundant security groups

module "fms_policies" {
  count  = var.create_fms_policies ? 1 : 0
  source = "./modules/fms_policies"

  # Organization Configuration
  org_ou_ids = var.org_ou_ids

  # Security Group IDs from sg_models module
  golden_sg_id      = module.sg_models.golden_sg_id
  allow_model_sg_id = module.sg_models.allow_sg_id
  deny_model_sg_id  = module.sg_models.deny_model_sg_id

  # Usage Audit Configuration
  usage_audit_unused_delay_minutes = var.usage_audit_unused_delay_minutes
}
