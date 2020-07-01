@echo off 

REM Handle args
if [%1]==[] goto usage
set env_name=%1
set region=%2
set mode=%3
set s3_bucket=s3-%env_name%-terraform-bucket

REM S3 section to create and manage bucket
aws s3 ls "s3://%s3_bucket%" >nul 2>&1
if errorlevel 1 (
    echo creating bucket...
    aws s3 mb "s3://%s3_bucket%" --region %region%
    if errorlevel 1 (
        echo Failed to create bucket
        goto :eof
    )
    aws s3api wait bucket-exists --bucket  %s3_bucket%
) else (
    echo Bucket already exist
)
REM enforce terraform bucket policies
aws s3api put-bucket-versioning --bucket %s3_bucket% --versioning-configuration Status=Enabled
aws s3api put-public-access-block --bucket %s3_bucket% --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"


REM Init Terraform and setup S3 backend
set TF_IN_AUTOMATION=true
terraform init -backend-config="bucket=%s3_bucket%" -backend-config="key=%env_name%.tfstate" -backend-config="region=%region%" -backend=true -force-copy -get=true -input=false

REM handle SSH key
if exist id_rsa (
    echo SSH exists
) else (
    ssh-keygen -N "" -f id_rsa
    aws s3 cp id_rsa s3://s3-assi-terraform-bucket/keys/
    aws s3 cp id_rsa.pub s3://s3-assi-terraform-bucket/keys/
)

if /i "%mode%"=="destroy" goto :destroy

REM Terraform apply
if /i "%mode%"=="quiet" set quiet_mode="-auto-approve"
terraform apply -var env_name=%env_name% -var region=%region% %quiet_mode%
set quiet_mode=

REM provision bastion
ssh-copy-id -i mykey.rsa.pub -o "IdentityFile hostkey.rsa" user@target

goto :eof

:destroy
REM Terraform Destroy
terraform destroy -var env_name=%env_name% -var region=%region%
goto :eof

:usage
@echo Usage: %0 env_name region quiet
exit /B 1