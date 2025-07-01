variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "eks-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the EKS cluster (internal subnets)"
  type        = list(string)
  
  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "At least 2 private subnets are required for high availability."
  }
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the EKS cluster (external subnets)"
  type        = list(string)
  
  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "At least 2 public subnets are required for high availability."
  }
}

# Computed variable for all subnets (for backward compatibility)
locals {
  all_subnet_ids = concat(var.private_subnet_ids, var.public_subnet_ids)
}

variable "enable_vpc_cni" {
  description = "Enable VPC CNI addon"
  type        = bool
  default     = true
}

variable "enable_coredns" {
  description = "Enable CoreDNS addon"
  type        = bool
  default     = true
}

variable "enable_kube_proxy" {
  description = "Enable kube-proxy addon"
  type        = bool
  default     = true
}

variable "enable_ebs_csi" {
  description = "Enable EBS CSI Driver addon"
  type        = bool
  default     = true
}

variable "node_groups" {
  description = "Map of node group configurations"
  type = map(object({
    instance_types = list(string)
    capacity_type  = string
    desired_size   = number
    max_size       = number
    min_size       = number
    labels         = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
    subnet_type = string # "private" or "public"
  }))
  default = {
    default = {
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      desired_size   = 2
      max_size       = 4
      min_size       = 1
      labels = {
        role = "default"
      }
      taints = []
      subnet_type = "private"
    }
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
      subnet_type = "private"
    }
  }
  
  validation {
    condition = alltrue([
      for group_name, group_config in var.node_groups : 
      contains(["private", "public"], group_config.subnet_type)
    ])
    error_message = "subnet_type must be either 'private' or 'public' for all node groups."
  }
}

variable "enable_alb_controller" {
  description = "Enable AWS Load Balancer Controller"
  type        = bool
  default     = true
}

variable "enable_external_secrets" {
  description = "Enable External Secrets Operator"
  type        = bool
  default     = false
}

variable "external_secrets_namespaces" {
  description = "Namespaces where External Secrets Operator will be deployed"
  type        = list(string)
  default     = ["default"]
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "eks-cluster"
    ManagedBy   = "terraform"
  }
}