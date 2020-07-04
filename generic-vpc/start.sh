#!/bin/bash

# Handle Args
if [ $# -lt 2 ]; then
    echo """
Must specify a minimum of 2 args, environment name and region

Usage: $0 env_name region [quiet, destroy]
"""
    exit 1
fi
ENV_NAME=$1
REGION=$2
MODE=$3
S3_BUCKET=s3-$ENV_NAME-terraform-bucket

# S3 section to create and manage bucket
if aws s3 ls "s3://$S3_BUCKET" --region $REGION ; then
    echo "Bucket already exist"
else
    echo "creating bucket..."
    if aws s3 mb "s3://$S3_BUCKET" --region $REGION ; then
        aws s3api wait bucket-exists --bucket $S3_BUCKET --region $REGION
    else
        echo "Failed to create bucket"
    fi
fi

# enforce terraform bucket policies
aws s3api put-bucket-versioning --bucket $S3_BUCKET --region $REGION --versioning-configuration Status=Enabled
aws s3api put-public-access-block --bucket $S3_BUCKET --region $REGION --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Init Terraform and setup S3 backend
export TF_IN_AUTOMATION=true
cd terraform
terraform init -backend-config="bucket=$S3_BUCKET" -backend-config="key=$ENV_NAME.tfstate" -backend-config="region=$REGION" -backend=true -force-copy -get=true -input=false

if [ "$MODE" == "destroy" ]; then
    # Terraform Destroy
    terraform destroy -var env_name=$ENV_NAME -var region=$REGION
    cd ../
else
    # handle SSH key
    if [ -f id_rsa ]; then
        echo "id_rsa exists."
    elif aws s3 ls s3://$S3_BUCKET/keys/master-keys/id_rsa ; then 
        aws s3 cp s3://$S3_BUCKET/keys/master-keys/id_rsa id_rsa
        aws s3 cp s3://$S3_BUCKET/keys/master-keys/id_rsa.pub id_rsa.pub
        echo "id_rsa pulled from S3"
    else
        ssh-keygen -N "" -f id_rsa
        aws s3 cp id_rsa s3://$S3_BUCKET/keys/master-keys/
        aws s3 cp id_rsa.pub s3://$S3_BUCKET/keys/master-keys/
    fi

    if [ "$MODE" == "quiet" ]; then
        QUIET_MODE=-auto-approve
    else
        echo "To avoid Terraform approve prompt. add 'quiet' as the third arg"
    fi
    terraform apply -var env_name=$ENV_NAME -var region=$REGION -var backend_bucket=$S3_BUCKET $QUIET_MODE
fi