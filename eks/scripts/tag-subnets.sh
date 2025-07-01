#!/bin/bash

# Script to tag subnets for EKS ALB Controller
# Usage: ./tag-subnets.sh <cluster-name> <private-subnet-ids> <public-subnet-ids>

set -e

if [ $# -ne 3 ]; then
    echo "Usage: $0 <cluster-name> <private-subnet-ids> <public-subnet-ids>"
    echo "Example: $0 my-eks-cluster 'subnet-12345 subnet-67890' 'subnet-11111 subnet-22222'"
    exit 1
fi

CLUSTER_NAME="$1"
PRIVATE_SUBNETS="$2"
PUBLIC_SUBNETS="$3"

# Function to validate and clean subnet ID
validate_subnet_id() {
    local subnet_id="$1"
    
    # Remove any non-alphanumeric characters except hyphens (clean up formatting chars)
    subnet_id=$(echo "$subnet_id" | sed 's/[^a-zA-Z0-9-]//g')
    
    # Check if it matches subnet-* pattern
    if [[ "$subnet_id" =~ ^subnet-[a-zA-Z0-9]+$ ]]; then
        echo "$subnet_id"
        return 0
    else
        echo "ERROR: Invalid subnet ID format: '$subnet_id'" >&2
        return 1
    fi
}

# Function to process and validate subnet list
process_subnet_list() {
    local subnet_string="$1"
    local validated_subnets=()
    
    # Split by whitespace and validate each subnet
    for subnet in $subnet_string; do
        if validated_id=$(validate_subnet_id "$subnet"); then
            validated_subnets+=("$validated_id")
        else
            echo "ERROR: Skipping invalid subnet ID: '$subnet'" >&2
        fi
    done
    
    echo "${validated_subnets[@]}"
}

echo "Tagging subnets for EKS cluster: $CLUSTER_NAME"
echo "================================================"

# Process and validate subnet lists
VALIDATED_PRIVATE_SUBNETS=($(process_subnet_list "$PRIVATE_SUBNETS"))
VALIDATED_PUBLIC_SUBNETS=($(process_subnet_list "$PUBLIC_SUBNETS"))

# Check if we have valid subnets to process
if [ ${#VALIDATED_PRIVATE_SUBNETS[@]} -eq 0 ] && [ ${#VALIDATED_PUBLIC_SUBNETS[@]} -eq 0 ]; then
    echo "ERROR: No valid subnet IDs found. Please check your input."
    exit 1
fi

# Tag private subnets
if [ ${#VALIDATED_PRIVATE_SUBNETS[@]} -gt 0 ]; then
    echo "Tagging private subnets..."
    for subnet in "${VALIDATED_PRIVATE_SUBNETS[@]}"; do
        echo "Tagging private subnet: $subnet"
        if ! aws ec2 create-tags --resources "$subnet" --tags \
            Key=kubernetes.io/role/internal-elb,Value=1 \
            Key=kubernetes.io/cluster/$CLUSTER_NAME,Value=shared; then
            echo "ERROR: Failed to tag private subnet: $subnet" >&2
            exit 1
        fi
    done
else
    echo "No valid private subnets to tag."
fi

# Tag public subnets
if [ ${#VALIDATED_PUBLIC_SUBNETS[@]} -gt 0 ]; then
    echo "Tagging public subnets..."
    for subnet in "${VALIDATED_PUBLIC_SUBNETS[@]}"; do
        echo "Tagging public subnet: $subnet"
        if ! aws ec2 create-tags --resources "$subnet" --tags \
            Key=kubernetes.io/role/elb,Value=1 \
            Key=kubernetes.io/cluster/$CLUSTER_NAME,Value=shared; then
            echo "ERROR: Failed to tag public subnet: $subnet" >&2
            exit 1
        fi
    done
else
    echo "No valid public subnets to tag."
fi

echo "================================================"
echo "Subnet tagging completed successfully!"
echo ""
echo "Required tags for ALB Controller:"
echo "- Private subnets: kubernetes.io/role/internal-elb = 1"
echo "- Public subnets: kubernetes.io/role/elb = 1"
echo "- All subnets: kubernetes.io/cluster/$CLUSTER_NAME = shared"
echo ""
echo "You can now run: terraform plan"
