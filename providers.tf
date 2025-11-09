/*
 * AWS Firewall Manager Security Group Policy - Provider Configuration
 * 
 * This file defines the Terraform and AWS provider requirements and configuration
 * for the FMS Security Group policy deployment.
 * 
 * IMPORTANT: This configuration should be deployed in the AWS account that has
 * been designated as the Firewall Manager administrator account within your
 * AWS Organization.
 */

# ============================================================================
# Terraform and Provider Requirements
# ============================================================================

terraform {
  # Minimum Terraform version required for this configuration
  # Version 1.7+ is required for advanced features like validation blocks
  required_version = "~> 1.7"

  # AWS Provider version constraints
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # AWS Provider 5.x includes latest FMS features and security improvements
      version = "~> 5.0"
    }
  }
}

# ============================================================================
# AWS Provider Configuration
# ============================================================================

provider "aws" {
  # AWS region where FMS policies and security groups will be created
  # Note: FMS is available in all AWS commercial regions
  region = var.region

  # Additional provider configuration can be added here:
  # - assume_role for cross-account deployment
  # - profile for specific AWS CLI profile
  # - default_tags for consistent resource tagging
  
  # Example default tags (uncomment and modify as needed):
  # default_tags {
  #   tags = {
  #     Environment = "production"
  #     Project     = "aws-fms-security-policy"
  #     ManagedBy   = "terraform"
  #   }
  # }
}