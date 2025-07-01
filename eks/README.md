# EKS Cluster Terraform Module

This Terraform module deploys a production-ready Amazon EKS cluster with common addons and configurations.

## Features

- **EKS Cluster**: Production-ready EKS cluster with configurable Kubernetes version
- **Node Groups**: Support for both on-demand and spot instances with configurable instance types
- **IAM Roles**: Proper IAM roles for cluster, nodes, and addons with IRSA (IAM Roles for Service Accounts)
- **Addons**: CoreDNS, kube-proxy, VPC CNI, and EBS CSI Driver
- **AWS Load Balancer Controller**: Optional ALB controller with proper IAM permissions
- **External Secrets Operator**: Optional ESO for secret management
- **Security**: OIDC provider for secure service account authentication
- **Automatic Cleanup**: Automatically removes kubectl context when destroying resources

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured
- kubectl installed
- VPC with proper subnets (public and private)

## Usage

1. **Clone and initialize**:
   ```bash
   terraform init
   ```

2. **Configure variables**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

3. **Plan and apply**:
   ```bash
   terraform plan
   terraform apply
   ```

4. **Configure kubectl**:
   ```bash
   aws eks update-kubeconfig --name <cluster-name> --region <region>
   ```

5. **Install addons** (if enabled):
   ```bash
   # For ALB Controller
   terraform output -raw alb_controller_helm_command | bash
   
   # For External Secrets
   terraform output -raw external_secrets_helm_command | bash
   ```

## Automatic Cleanup

When you run `terraform destroy`, the module automatically cleans up your kubectl configuration:

- **Removes kubectl context** for the cluster
- **Removes kubectl cluster** configuration
- **Removes kubectl user** configuration

This prevents orphaned kubectl configurations from accumulating in your `~/.kube/config` file.

### Manual Cleanup (if needed)

If you need to manually clean up kubectl context, you can use the output commands:

```bash
# Get cleanup commands
terraform output kubectl_context_deletion_commands

# Or run them directly
kubectl config delete-context <cluster-name>
kubectl config delete-cluster <cluster-name>
kubectl config delete-user <cluster-name>
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aws_region | AWS region | `string` | `"us-east-1"` | no |
| cluster_name | Name of the EKS cluster | `string` | `"eks-cluster"` | no |
| cluster_version | Kubernetes version for the EKS cluster | `string` | `"1.28"` | no |
| vpc_id | VPC ID where the EKS cluster will be deployed | `string` | n/a | yes |
| subnet_ids | List of subnet IDs for the EKS cluster | `list(string)` | n/a | yes |
| node_groups | Map of node group configurations | `map(object)` | See variables.tf | no |
| enable_alb_controller | Enable AWS Load Balancer Controller | `bool` | `true` | no |
| enable_external_secrets | Enable External Secrets Operator | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | EKS cluster ID |
| cluster_arn | EKS cluster ARN |
| cluster_endpoint | EKS cluster endpoint |
| cluster_name | EKS cluster name |
| kubeconfig_command | Command to configure kubectl |
| alb_controller_helm_command | Helm command to install ALB Controller |
| external_secrets_helm_command | Helm command to install ESO |

## Node Groups

The module supports multiple node groups with different configurations:

- **Default**: On-demand instances for general workloads
- **Spot**: Spot instances for cost optimization

Each node group can be configured with:
- Instance types
- Capacity type (ON_DEMAND or SPOT)
- Scaling configuration
- Labels and taints

## Security

- All IAM roles use least privilege principles
- OIDC provider for secure service account authentication
- IRSA (IAM Roles for Service Accounts) for addons
- Proper security group configurations

## Addons

### CoreDNS
- DNS server for the cluster
- Automatically installed

### kube-proxy
- Network proxy for the cluster
- Automatically installed

### VPC CNI
- Amazon VPC CNI plugin
- Automatically installed

### EBS CSI Driver
- EBS volume support
- Requires IAM role with proper permissions

### AWS Load Balancer Controller
- Manages ALB/NLB resources
- Optional installation via Helm

### External Secrets Operator
- Manages secrets from external sources
- Optional installation per namespace

## Backend Configuration

The module uses a conditional backend approach that automatically detects whether an S3 bucket exists and configures the appropriate backend:

- **If S3 bucket exists**: Uses S3 backend with bucket `<account-id>-tf`
- **If S3 bucket doesn't exist**: Uses local state file `terraform.tfstate`

### Backend Setup

The backend is automatically configured when you run `./scripts/init-backend.sh`. This script:

1. Gets your AWS account ID using `aws sts get-caller-identity`
2. Checks if the S3 bucket `<account-id>-tf` exists
3. Creates the appropriate backend configuration:
   - **S3 backend** if bucket exists: `s3://<account-id>-tf/eks/terraform.tfstate`
   - **Local backend** if bucket doesn't exist: `terraform.tfstate`
4. Initializes Terraform with the chosen backend

### Backend Configuration Details

#### S3 Backend (when bucket exists)
- **Bucket**: `<account-id>-tf` (e.g., `123456789012-tf`)
- **Key**: `eks/terraform.tfstate`
- **Region**: `eu-west-1`

#### Local Backend (when bucket doesn't exist)
- **Path**: `terraform.tfstate` (local file)

### Manual Backend Configuration

If you prefer to configure the backend manually:

```bash
# Get your account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Check if bucket exists
if aws s3 ls "s3://$ACCOUNT_ID-tf" &> /dev/null; then
    echo "Using S3 backend"
    terraform init \
      -backend-config="bucket=$ACCOUNT_ID-tf" \
      -backend-config="key=eks/terraform.tfstate" \
      -backend-config="region=eu-west-1"
else
    echo "Using local backend"
    terraform init
fi
```

### Creating S3 Bucket for Backend

If you want to use S3 backend but the bucket doesn't exist:

```bash
# Get your account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create the bucket
aws s3 mb s3://$ACCOUNT_ID-tf --region eu-west-1

# Re-run the initialization script
./scripts/init-backend.sh
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License. 