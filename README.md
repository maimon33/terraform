# terraform
General purpose terraform stacks

## Generic VPC

Creates a VPC with misc services.

### Start
*

## EKS cluster

Creates a VPC and all required resources to host AWS managed k8s cluster.

### Start
* terraform init -backend-config="bucket=fdna-${ENV}-$2-terraform" -backend-config="key=$2.tfstate" -backend-config="region=eu-west-1" -backend=true -force-copy -get=true -input=false
* erraform apply -var cluster-name=my_cluster -var environment=my_env -var keypair=my_key
