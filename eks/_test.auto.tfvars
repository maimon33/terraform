# AWS Configuration
aws_region = "us-east-1"

# Cluster Configuration
cluster_name    = "test-dev2"
cluster_version = "1.33"

# VPC Configuration
vpc_id = "vpc-0e5571c80c339cbe3"
# subnet_ids = ["subnet-061f6497ff1b7a98f", "subnet-0626864eb78be6067", "subnet-000e678b3055f32cd", "subnet-088deabddc35a7e3b", "subnet-0f6c542d945f59d06", "subnet-081f61538905122fe"]
private_subnet_ids = ["subnet-061f6497ff1b7a98f", "subnet-0626864eb78be6067", "subnet-000e678b3055f32cd"]
public_subnet_ids = ["subnet-088deabddc35a7e3b", "subnet-0f6c542d945f59d06", "subnet-081f61538905122fe"]

# Node Groups Configuration
node_groups = {
  spot = {
    instance_types = ["t3.medium", "t3a.medium"]
    capacity_type  = "SPOT"
    desired_size   = 2
    max_size       = 4
    min_size       = 1
    labels = {
      role = "spot"
    }
    taints = []
    subnet_type = "private"  # Use private subnets for worker nodes
  }
}

# Addons Configuration
enable_vpc_cni = true
enable_coredns = true
enable_kube_proxy = true
enable_ebs_csi = true

# AWS Load Balancer Controller
enable_alb_controller = true

# External Secrets Operator
enable_external_secrets = true
external_secrets_namespaces = ["default"]

# Tags
default_tags = {
  Environment = "dev"
  Project     = "eks-cluster"
  ManagedBy   = "terraform"
}