#!/bin/bash

# Setup script for AWS FMS Terraform permissions
# This script helps configure the necessary IAM permissions for Terraform to manage FMS policies

set -e

echo "🔧 AWS Firewall Manager - Terraform IAM Setup"
echo "=============================================="

# Get current AWS identity
echo "📋 Current AWS Identity:"
aws sts get-caller-identity --output table

echo ""
echo "🔍 Checking current permissions..."

# Check if user can list FMS policies
if aws fms list-policies --region us-east-1 >/dev/null 2>&1; then
    echo "✅ FMS permissions are already configured"
    exit 0
else
    echo "❌ Missing FMS permissions"
fi

echo ""
echo "🛠️  Setting up IAM permissions..."

# Get the current user name
USER_ARN=$(aws sts get-caller-identity --query Arn --output text)
USER_NAME=$(echo $USER_ARN | sed 's/.*user\///')

echo "👤 IAM User: $USER_NAME"

# Option 1: Use managed policy (recommended)
echo ""
echo "Option 1: Attach AWS managed FMS policy (recommended)"
read -p "Attach FMSServiceRolePolicy to $USER_NAME? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "📎 Attaching FMSServiceRolePolicy..."
    aws iam attach-user-policy \
        --user-name "$USER_NAME" \
        --policy-arn arn:aws:iam::aws:policy/FMSServiceRolePolicy
    echo "✅ Attached FMSServiceRolePolicy"
fi

# Option 2: Create custom policy
echo ""
echo "Option 2: Create minimal custom policy"
read -p "Create and attach minimal FMS policy? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    POLICY_NAME="TerraformFMSPolicy"
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    
    echo "📝 Creating IAM policy: $POLICY_NAME"
    
    # Create the policy
    POLICY_ARN=$(aws iam create-policy \
        --policy-name "$POLICY_NAME" \
        --policy-document file://terraform-fms-policy.json \
        --description "Minimal permissions for Terraform to manage AWS FMS policies" \
        --query 'Policy.Arn' \
        --output text)
    
    echo "📎 Attaching policy to user..."
    aws iam attach-user-policy \
        --user-name "$USER_NAME" \
        --policy-arn "$POLICY_ARN"
    
    echo "✅ Created and attached custom policy: $POLICY_ARN"
fi

echo ""
echo "🧪 Testing permissions..."
sleep 2

if aws fms list-policies --region us-east-1 >/dev/null 2>&1; then
    echo "✅ FMS permissions are working correctly!"
    echo ""
    echo "🚀 You can now run: terraform apply -var-file=prod.tfvars"
else
    echo "❌ FMS permissions still not working"
    echo "💡 Manual steps:"
    echo "   1. Ensure you're in the FMS administrator account"
    echo "   2. Verify AWS Config is enabled"
    echo "   3. Check that the account has delegated FMS admin rights"
fi

echo ""
echo "✨ Setup complete!"