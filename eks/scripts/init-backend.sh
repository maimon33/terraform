#!/bin/bash

# Script to initialize Terraform backend conditionally
# Usage: ./scripts/init-backend.sh

set -e

echo "🚀 Initializing Terraform backend conditionally..."
echo "=================================================="

# Check if AWS CLI is available
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed or not in PATH"
    exit 1
fi

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured. Please run 'aws configure' first."
    exit 1
fi

# Get AWS account ID
echo "📋 Getting AWS account ID..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

if [ -z "$ACCOUNT_ID" ]; then
    echo "❌ Failed to get AWS account ID. Make sure AWS CLI is configured."
    exit 1
fi

BUCKET_NAME="$ACCOUNT_ID-tf"
echo "✅ AWS Account ID: $ACCOUNT_ID"
echo "📦 Checking bucket: $BUCKET_NAME"

# Check if S3 bucket exists
echo "🔍 Checking if S3 bucket exists..."
if aws s3 ls "s3://$BUCKET_NAME" &> /dev/null; then
    echo "✅ S3 bucket $BUCKET_NAME exists - using S3 backend"
    
    # Create S3 backend configuration
    cat > backend.tf << EOF
# S3 Backend Configuration (auto-generated)
# Bucket exists, using S3 backend for state management

terraform {
  backend "s3" {
    bucket  = "$BUCKET_NAME"
    key     = "eks/terraform.tfstate"
    region  = "eu-west-1"
  }
}
EOF

    echo "📝 Created S3 backend configuration"
    echo "   Bucket: $BUCKET_NAME"
    echo "   Key: eks/terraform.tfstate"
    echo "   Region: eu-west-1"
    
else
    echo "⚠️  S3 bucket $BUCKET_NAME does not exist - using local state"
    
    # Create local backend configuration
    cat > backend.tf << EOF
# Local Backend Configuration (auto-generated)
# S3 bucket does not exist, using local state

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
EOF

    echo "📝 Created local backend configuration"
    echo "   State file: terraform.tfstate (local)"
    echo ""
    echo "💡 To use S3 backend, create the bucket first:"
    echo "   aws s3 mb s3://$BUCKET_NAME --region eu-west-1"
    echo "   Then run this script again."
fi

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

echo "=================================================="
echo "✅ Backend initialization completed!"
echo ""
echo "🎯 Next steps:"
echo "  terraform plan"
echo "  terraform apply"
echo ""
echo "📝 Note: Backend configuration is in backend.tf"
echo "   Run this script again if you create the S3 bucket later." 