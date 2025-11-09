# Terraform deployment configuration
region = "us-east-1"
vpc_id = "vpc-fa74579f"

# Enable Firewall Manager policies (Common, Content-Audit ALLOW/DENY, Usage-Audit)
create_fms_policies = true
org_ou_ids          = ["o-xspfq7zasv"]

# Usage audit retention before auto-delete unused SGs
usage_audit_unused_delay_minutes = 43200 # 30 days

# Default options for SG models
create_golden      = true
create_allow_model = true
create_deny_model  = true

# Golden SG (Baseline attach)
golden_sg_name             = "golden-baseline-egress"
golden_default_deny_egress = true
golden_allowed_egress_ports = [443, 80]
golden_allowed_egress_cidrs = ["0.0.0.0/0"]
# AllowModel SG (ALLOW list)
allow_model_sg_name      = "fms-allow-model"
allow_http_from_internet = true

# DenyModel SG (DENY list)
deny_model_sg_name = "fms-deny-model"
deny_admin_ports   = [22, 3859, 6739, 5432, 3306]
